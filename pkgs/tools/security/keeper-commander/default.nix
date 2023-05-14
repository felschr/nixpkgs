{ lib
, fetchFromGitHub
, python3
, python3Packages
, gitUpdater
}:

let
  paramiko-expect = python3Packages.buildPythonPackage rec {
    pname = "paramiko-expect";
    version = "0.3.5";

    src = fetchFromGitHub {
      owner = "fgimian";
      repo = "paramiko-expect";
      rev = "refs/tags/v${version}";
      hash = "sha256-CYR4arYIaYKf0eLR2UADCMQHHZD9BEp2G7taO//4RkY=";
    };

    propagatedBuildInputs = with python3Packages; [ paramiko ];

    passthru.updateScript = gitUpdater { rev-prefix = "v"; };

    meta = with lib; {
      description = "A Python expect-like extension for the Paramiko SSH library which also supports tailing logs.";
      homepage = "https://github.com/fgimian/paramiko-expect";
      license = licenses.mit;
      maintainers = with maintainers; [ myhlamaeus felschr ];
    };
  };

  keeper-secrets-manager-helper = python3Packages.buildPythonPackage {
    pname = "keeper-secrets-manager-helper";
    version = "1.0.4";

    # @TODO alternatively use fetchFromPypi with version
    src = fetchFromGitHub {
      owner = "Keeper-Security";
      repo = "secrets-manager";
      # @TODO commit not tagged
      rev = "ac75078c41f1ec0c611f09194e8336cfa0443cdc";
      hash = "sha256-ICWi0GT69Vpf4P8zljokam8z0u0NBttIehM3hxl504k=";
    };

    propagatedBuildInputs = with python3Packages; [
      # @TODO circular dependency, but doesn't seem to be needed
      # keeper-secrets-manager-core
      pyyaml
      iso8601
    ];

    postPatch = ''
      substituteInPlace sdk/python/helper/setup.py \
        --replace "'keeper-secrets-manager-core>=16.2.2'," ""
    '';

    preConfigure = ''
      cd sdk/python/helper
    '';

    meta = with lib; {
      description = "Keeper Secrets Manager Helper";
      homepage = "https://github.com/Keeper-Security/secrets-manager/sdk/python/helper";
      license = licenses.mit;
      maintainers = with maintainers; [ myhlamaeus felschr ];
    };
  };

  keeper-secrets-manager-core = python3Packages.buildPythonPackage rec {
    pname = "keeper-secrets-manager-core";
    version = "16.5.3";

    src = fetchFromGitHub {
      owner = "Keeper-Security";
      repo = "secrets-manager";
      rev = "refs/tags/python-sdk-v${version}";
      hash = "sha256-WmcXGn0F+H85XZ1H143fR5vSm2c1c0Ho0ZTaQRJ9xN0=";
    };

    propagatedBuildInputs = with python3Packages; [
      keeper-secrets-manager-helper
      ecdsa
      cryptography
      requests
      pytest
      importlib-metadata
    ];

    preConfigure = ''
      cd sdk/python/core
    '';

    passthru.updateScript = gitUpdater { rev-prefix = "python-sdk-v"; };

    meta = with lib; {
      description = "Keeper Secrets Manager Python SDK";
      homepage = "https://docs.keeper.io/secrets-manager/secrets-manager/developer-sdk-library/python-sdk";
      license = licenses.mit;
      maintainers = with maintainers; [ myhlamaeus felschr ];
    };
  };
in python3Packages.buildPythonApplication rec {
  pname = "keeper-commander";
  version = "16.9.3";

  src = fetchFromGitHub {
    owner = "Keeper-Security";
    repo = "Commander";
    rev = "refs/tags/v${version}";
    sha256 = "sha256-EDz28/XgC1+ERTV54nZEp5q439W6Z1mwerdNM0crrN4=";
  };

  propagatedBuildInputs = with python3Packages; [
    wheel
    asciitree
    bcrypt
    colorama
    cryptography
    paramiko
    paramiko-expect
    prompt_toolkit
    protobuf
    pycryptodomex
    pykeepass
    pyperclip
    pysocks
    pytest
    requests
    tabulate
    keeper-secrets-manager-core

    # @TODO extra_dependencies.txt
    fido2
    pykeepass
    # pyinstaller

    # @TODO optional dependencies (tests fail without them)
    psycopg2
    oracledb
    pymysql
    # pymssql # @TODO abandoned upstream
  ];

  nativeCheckInputs = with python3Packages; [
    pytest
    pexpect
  ];

  # @TODO lots of tests failing due to missing optional dependencies
  doCheck = false;

  # @TODO disable tests for optional dependencies
  disabledTests = [
    # pymssql is abandoned upstream, so disable these tests entirely
    # @TODO figure out correct tests to disable
    "mssql"
    "keepercommander.plugins.mssql"
  # ] ++ lib.optionals (withPostgresql) [
  # ] ++ lib.optionals (withOracledb) [
  # ] ++ lib.optionals (withMysql) [
  ];

  passthru.updateScript = gitUpdater { rev-prefix = "v"; };

  meta = with lib; {
    description = "A python-based CLI and SDK interface to the Keeper Security platform";
    homepage = "https://github.com/Keeper-Security/Commander";
    license = licenses.mit;
    maintainers = with maintainers; [ myhlamaeus felschr ];
    mainProgram = "keeper";
  };
}
