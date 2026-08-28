{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  python3Packages,
  pkg-config,
  eigen,
  fftwFloat,
  ffmpeg,
  libsamplerate,
  taglib,
  libyaml,
  chromaprint,
  zlib,
  nix-update-script,
  enablePython ? false,
  enableTensorFlow ? false,
}:

let
  libtensorflowVersion = "2.15.0";

  # Essentia links TensorFlow support against the official prebuilt
  # libtensorflow C API rather than a source build of TensorFlow, mirroring
  # upstream's own src/3rdparty/tensorflow/setup_from_libtensorflow.sh helper.
  libtensorflow = stdenv.mkDerivation {
    pname = "libtensorflow";
    version = libtensorflowVersion;

    src = fetchurl {
      url = "https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-linux-x86_64-${libtensorflowVersion}.tar.gz";
      hash = "sha256-8P0etdueTgYD8QrsKJV00d7LVPc7Z18M5Hb+ofBYOMg=";
    };

    sourceRoot = ".";

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -a lib include $out/

      mkdir -p $out/lib/pkgconfig
      cat > $out/lib/pkgconfig/tensorflow.pc <<EOF
      prefix=$out
      libdir=\''${prefix}/lib
      includedir=\''${prefix}/include

      Name: tensorflow
      Description: TensorFlow C API
      Version: ${libtensorflowVersion}
      Libs: -L\''${libdir} -ltensorflow
      Cflags: -I\''${includedir}
      EOF

      runHook postInstall
    '';
  };
in

stdenv.mkDerivation (finalAttrs: {
  pname = "essentia";
  version = "2.1-beta6-unstable-2026-08-27";

  src = fetchFromGitHub {
    owner = "MTG";
    repo = "essentia";
    rev = "66a890f285d0e1988155c12d17a2068e406cdd90";
    hash = "sha256-xVL1sUIVDarBIH15dkY0hsGLwrh3NhI0EEqEOEih4dI=";
  };

  nativeBuildInputs = [
    (python3Packages.python.withPackages (
      ps:
      [ ps.setuptools ]
      ++ lib.optionals enablePython [
        ps.numpy
        ps.pyyaml
        ps.six
      ]
    ))
    pkg-config
  ]
  ++ lib.optionals enablePython [ python3Packages.pythonImportsCheckHook ];

  buildInputs = [
    eigen
    fftwFloat
    ffmpeg
    libsamplerate
    taglib
    libyaml
    chromaprint
    zlib
  ]
  ++ lib.optional enableTensorFlow libtensorflow;

  propagatedBuildInputs = lib.optionals enablePython [
    python3Packages.numpy
    python3Packages.pyyaml
    python3Packages.six
  ];

  configurePhase = ''
    runHook preConfigure

    python3 waf configure --prefix=$out --with-examples --with-vamp \
      ${lib.optionalString enablePython "--with-python --pythondir=$out/${python3Packages.python.sitePackages}"} \
      ${lib.optionalString enableTensorFlow "--with-tensorflow"}

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    python3 waf

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    python3 waf install

    runHook postInstall
  '';

  pythonImportsCheck = lib.optionals enablePython [ "essentia" ];

  passthru = {
    updateScript = nix-update-script { };
  }
  // lib.optionalAttrs enablePython { pythonModule = python3Packages.python; };

  meta = {
    description = "C++ library for audio and music analysis, description and synthesis";
    longDescription = ''
      Essentia is an open-source C++ library for audio analysis and
      audio-based music information retrieval. It contains an extensive
      collection of reusable algorithms which implement audio input/output
      functionality, standard digital signal processing blocks, statistical
      characterization of data, and a large set of spectral, temporal, tonal
      and high-level music descriptors. It also includes a number of
      predefined executable extractors for the available music descriptors
      and a Vamp plugin to be used with Sonic Visualiser.

      This build tracks the actively developed `master` branch, since
      upstream recommends installing from master for the latest updates and
      has not tagged an official release since 2019.
    '';
    homepage = "https://essentia.upf.edu";
    changelog = "https://github.com/MTG/essentia/blob/${finalAttrs.src.rev}/Changelog";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ felschr ];
    platforms = lib.platforms.linux;
    mainProgram = "essentia_streaming_extractor_music";
  };
})
