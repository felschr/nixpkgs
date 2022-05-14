{ lib
, stdenv
, mkDerivation
, fetchFromGitHub
, cmake
, pkg-config
, ninja
, freetype
, harfbuzz
, libyamlcpp
, libsForQt5
, libGL
, pcre
, nixosTests
, fmt
, ncurses
, catch2
, range-v3
, microsoft_gsl
}:

let
  libunicode = mkDerivation rec {
    pname = "libunicode";
    version = "2022-02-26";

    src = fetchFromGitHub {
      owner = "contour-terminal";
      repo = pname;
      rev = "94e0eeadadf61a957b1184ea276e7d94e0d40cf9";
      sha256 = "sha256-ODz9UZuQU4H64HwHYXvapXvobSk64pAwPyTAOlcLhmM=";
    };

    outputs = [ "out" "dev" ];

    nativeBuildInputs = [ cmake pkg-config ninja ];

    buildInputs = [ fmt catch2 range-v3 microsoft_gsl ];

    # TODO nothing seem to work for contour build to be happy
    installPhase = ''
      mkdir -p $out/lib
      cp ./src/unicode/*.a $out/lib
      cp $src/src/unicode/*.h $out/lib

      mkdir -p $dev/include/libunicode
      cp $src/src/unicode/*.h $dev
      # cp $src/src/unicode/*.h $dev/include/libunicode

      mkdir -p $out/include/libunicode
      cp $src/src/unicode/*.h $out/include/libunicode

      mkdir -p $out/bin
      cp $src/src/tools/* $out/bin
    '';

    doCheck = true;

    meta = with lib; {
      description = "Modern C++17 unicode library";
      homepage = "https://github.com/contour-terminal/libunicode";
      license = licenses.asl20;
      maintainers = with maintainers; [ felschr ];
      platforms = platforms.unix;
    };
  };
in
mkDerivation rec {
  pname = "contour";
  version = "0.3.1.200";

  src = fetchFromGitHub {
    owner = "contour-terminal";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-TpxVC0GFZD3jGISnDWHKEetgVVpznm5k/Vc2dwVfSG4=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ cmake pkg-config ninja ];

  buildInputs = [
    freetype
    harfbuzz
    libunicode
    libyamlcpp
    libsForQt5.qt5.qtbase
    libGL
    pcre
    fmt
    ncurses
    catch2
    range-v3
    microsoft_gsl
  ];

  # TODO libunicode can't be found for some reason
  preConfigure = ''
    ls -la ${libunicode}/lib
    # exit 42

    substituteInPlace cmake/ContourThirdParties.cmake \
      --replace "ContourThirdParties_Embed_libunicode()" "" \
      --replace "ContourThirdParties_Embed_termbench_pro()" ""
  '';

  doCheck = true;

  passthru.tests.test = nixosTests.terminal-emulators.contour;

  meta = with lib; {
    description = "Modern C++ Terminal Emulator";
    homepage = "https://github.com/contour-terminal/contour";
    changelog = "https://github.com/contour-terminal/contour/blob/HEAD/Changelog.md";
    license = licenses.asl20;
    maintainers = with maintainers; [ fortuneteller2k felschr ];
    platforms = platforms.unix;
    broken = stdenv.isDarwin; # never built on Hydra https://hydra.nixos.org/job/nixpkgs/staging-next/contour.x86_64-darwin
  };
}
