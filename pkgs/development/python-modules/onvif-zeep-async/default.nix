{ lib
, buildPythonPackage
# , fetchPypi
, fetchFromGitHub
, zeep
, httpx
}:

buildPythonPackage rec {
  pname = "onvif-zeep-async";
  version = "1.2.0";

  # no tests available
  doCheck = false;

  src = fetchPypi {
    inherit pname version;
    sha256 = "O4H6oL9cFvgX6whoESA7eRI6+VoT1ncRk/tehQT1WcM=";
  };

  propagatedBuildInputs = [
    zeep
    httpx
  ];

  meta = with lib; {
    description = "Async Python Client for ONVIF Camera";
    homepage = "https://github.com/hunterjm/python-onvif-zeep-async";
    license = licenses.mit;
    maintainers = with maintainers; [ felschr ];
  };
}
