{ lib, stdenv
, fetchurl
, makeDesktopItem
, makeWrapper

# Common run-time dependencies
, zlib

# libxul run-time dependencies
, atk
, cairo
, dbus
, dbus-glib
, fontconfig
, freetype
, gdk-pixbuf
, glib
, gtk3
, libxcb
, libX11
, libXext
, libXrender
, libXt
, libXtst
, pango

, libnotifySupport ? stdenv.isLinux
, libnotify ? libnotifySupport

, audioSupport ? mediaSupport
, pulseaudioSupport ? mediaSupport
, libpulseaudio
, apulse
, alsa-lib

# Media support (implies audio support)
, mediaSupport ? true
, ffmpeg

# Whether to disable multiprocess support
, disableContentSandbox ? false

# Extra preferences
, extraPrefs ? ""
}:

let
  libPath = lib.makeLibraryPath libPkgs;

  libPkgs = [
    alsa-lib
    atk
    cairo
    dbus
    dbus-glib
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libxcb
    libX11
    libXext
    libXrender
    libXt
    libXtst
    pango
    stdenv.cc.cc
    stdenv.cc.libc
    zlib
  ]
  ++ lib.optionals libnotifySupport [ libnotify ]
  ++ lib.optionals pulseaudioSupport [ libpulseaudio ]
  ++ lib.optionals mediaSupport [ ffmpeg ];

  # Upstream source
  version = "12.0.4";

  lang = "ALL";

  srcs = {
    x86_64-linux = fetchurl {
      urls = [
        "https://github.com/mullvad/mullvad-browser/releases/download/mullvad-browser-102.9.0esr-12.0-2-build1/mullvad-browser-linux64-${version}_${lang}.tar.xz"
      ];
      hash = "sha256-q4dTKNQkcqaRwiF25iVOQSvwVLA3tJRlQ4DzC3tuG5A=";
    };
  };
in
stdenv.mkDerivation rec {
  pname = "mullvad-browser";
  inherit version;

  src = srcs.${stdenv.hostPlatform.system} or (throw "unsupported system: ${stdenv.hostPlatform.system}");

  nativeBuildInputs = [ makeWrapper ];

  preferLocalBuild = true;
  allowSubstitutes = false;

  desktopItem = makeDesktopItem {
    name = "mullvad-browser";
    exec = "mullvad-browser %U";
    icon = "mullvad-browser";
    desktopName = "Mullvad Browser";
    genericName = "Web Browser";
    comment = meta.description;
    categories = [ "Network" "WebBrowser" "Security" ];
  };

  buildCommand = ''
    # For convenience ...
    MB_IN_STORE=$out/share/mullvad-browser
    interp=$(< $NIX_CC/nix-support/dynamic-linker)

    # Unpack & enter
    mkdir -p "$MB_IN_STORE"
    tar xf "$src" -C "$MB_IN_STORE" --strip-components=2
    pushd "$MB_IN_STORE"

    # Set ELF interpreter
    echo "Setting ELF interpreter ..." >&2
    patchelf --set-interpreter "$interp" "mullvadbrowser.real"

    # mullvadbrowser is a wrapper that checks for a more recent libstdc++ & appends it to the ld path
    mv mullvadbrowser.real mullvadbrowser

    touch "$MB_IN_STORE/system-install"

    # The final libPath.
    libPath=${libPath}:$MB_IN_STORE

    # apulse uses a non-standard library path.  For now special-case it.
    ${lib.optionalString (audioSupport && !pulseaudioSupport) ''
      libPath=${apulse}/lib/apulse:$libPath
    ''}

    # Prepare for autoconfig.
    #
    # See https://developer.mozilla.org/en-US/Firefox/Enterprise_deployment
    cat >defaults/pref/autoconfig.js <<EOF
    //
    pref("general.config.filename", "mozilla.cfg");
    pref("general.config.obscure_value", 0);
    EOF

    # Hard-coded Firefox preferences.
    cat >mozilla.cfg <<EOF
    // First line must be a comment

    // Always update via Nixpkgs
    lockPref("app.update.auto", false);
    lockPref("app.update.enabled", false);
    lockPref("extensions.update.autoUpdateDefault", false);
    lockPref("extensions.update.enabled", false);
    lockPref("extensions.torbutton.versioncheck_enabled", false);

    // Reset pref that captures store paths.
    clearPref("extensions.xpiState");

    // Stop obnoxious first-run redirection.
    lockPref("noscript.firstRunRedirection", false);

    // Optionally disable multiprocess support.  We always set this to ensure that
    // toggling the pref takes effect.
    lockPref("browser.tabs.remote.autostart.2", ${if disableContentSandbox then "false" else "true"});

    // Allow sandbox access to sound devices if using ALSA directly
    ${if (audioSupport && !pulseaudioSupport) then ''
      pref("security.sandbox.content.write_path_whitelist", "/dev/snd/");
    '' else ''
      clearPref("security.sandbox.content.write_path_whitelist");
    ''}

    ${lib.optionalString (extraPrefs != "") ''
      ${extraPrefs}
    ''}
    EOF

    # FONTCONFIG_FILE is required to make fontconfig read the MB
    # fonts.conf; upstream uses FONTCONFIG_PATH, but FC_DEBUG=1024
    # indicates the system fonts.conf being used instead.
    FONTCONFIG_FILE=$MB_IN_STORE/fontconfig/fonts.conf
    sed -i "$FONTCONFIG_FILE" \
      -e "s,<dir>fonts</dir>,<dir>$MB_IN_STORE/fonts</dir>,"

    mkdir -p $out/bin

    makeWrapper "$MB_IN_STORE/mullvadbrowser" "$out/bin/mullvad-browser" \
      --set LD_LIBRARY_PATH "$libPath" \
      --set FONTCONFIG_FILE "$FONTCONFIG_FILE"

    # Easier access to docs
    mkdir -p $out/share/doc
    ln -s $MB_IN_STORE/Data/Docs $out/share/doc/mullvad-browser

    # Install .desktop item
    mkdir -p $out/share/applications
    cp $desktopItem/share/applications"/"* $out/share/applications
    for i in 16 32 48 64 128; do
      mkdir -p $out/share/icons/hicolor/''${i}x''${i}/apps/
      ln -s $out/share/mullvad-browser/browser/chrome/icons/default/default$i.png $out/share/icons/hicolor/''${i}x''${i}/apps/mullvad-browser.png
    done

    # Check installed apps
    echo "Checking mullvad-browser wrapper ..."
    $out/bin/mullvad-browser --version >/dev/null
  '';

  meta = with lib; {
    description = "Privacy-focused browser made in a collaboration between The Tor Project and Mullvad";
    homepage = "https://www.mullvad.net/en/browser";
    changelog = "https://github.com/mullvad/mullvad-browser/releases";
    platforms = attrNames srcs;
    maintainers = with maintainers; [ felschr ];
    mainProgram = "mullvad-browser";
    # MPL2.0+, GPL+, &c.  While it's not entirely clear whether
    # the compound is "libre" in a strict sense (some components place certain
    # restrictions on redistribution), it's free enough for our purposes.
    license = licenses.free;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
