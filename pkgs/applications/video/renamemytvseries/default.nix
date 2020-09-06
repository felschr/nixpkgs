{ stdenv, fetchurl, makeWrapper, autoPatchelfHook, makeDesktopItem

, glib, libnotify, sqlite, cairo, atk, pango, gtk2
, openssl
}:

let
  pname = "RenameMyTVSeries";
  version = "2.0.10";

  desktopItem = makeDesktopItem {
    name = pname;
    desktopName = "Rename My TV-Series";
    exec = pname;
    comment = "Rename your TV-Seris using TheTVDB";
    categories = "AudioVideo";
    icon = pname;
  };

in

stdenv.mkDerivation rec {
  inherit pname version;

  name = "${pname}-${version}";

  src = fetchurl {
    url = "https://www.tweaking4all.com/downloads/video/RenameMyTVSeries-${version}-Linux64bit.tar.gz";
    sha256 = "18bb3w3877r7712zzg91k5v3g6hz6paxh1ljs3cp092nmcha8m1y";
  };

  unpackPhase = ''tar xvf $src'';

  nativeBuildInputs = [ makeWrapper autoPatchelfHook ];

  buildInputs = [ stdenv.cc.cc.lib glib libnotify sqlite cairo atk pango gtk2 ];

  runtimeDependencies = [
    openssl.out
  ];

  dontBuild = true;
  installPhase = ''
    mkdir -p $out/bin $out/share/applications
    install -dm755 $out/opt/${pname}
    install -Dm755 ffprobe $out/opt/${pname}/
    install -Dm755 RenameMyTVSeries $out/opt/${pname}/
    install -Dm644 icons/16x16.png $out/usr/share/icons/hicolor/16x16/apps/${pname}.png
    install -Dm644 icons/32x32.png $out/usr/share/icons/hicolor/32x32/apps/${pname}.png
    install -Dm644 icons/64x64.png $out/usr/share/icons/hicolor/64x64/apps/${pname}.png
    install -Dm644 icons/128x128.png $out/usr/share/icons/hicolor/128x128/apps/${pname}.png
    install -Dm644 icons/256x256.png $out/usr/share/icons/hicolor/256x256/apps/${pname}.png
    wrapProgram $out/opt/RenameMyTVSeries/RenameMyTVSeries
    ln -s $out/opt/RenameMyTVSeries/RenameMyTVSeries $out/bin/RenameMyTVSeries
    ln -s ${desktopItem}/share/applications/${pname}.desktop $out/share/applications/${pname}.desktop
  '';

  meta = with stdenv.lib; {
    description = "Rename your TV-Series using TheTVDB";
    homepage = https://www.tweaking4all.com/home-theatre/rename-my-tv-series-v2/;
    license = licenses.unfreeRedistributable;
    maintainers = with maintainers; [ felschr ];
    platforms = platforms.linux;
  };
}
