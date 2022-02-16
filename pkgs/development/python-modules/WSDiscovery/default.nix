{ lib
, buildPythonPackage
, fetchPypi
, netifaces
, click
, pytest
, mock
}:

buildPythonPackage rec {
  pname = "WSDiscovery";
  version = "2.0.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sPnDahH5pWkFIjkVwzwpX0JApqJd5gsyswXL5pIC7ng=";
  };

  checkInputs = [ pytest mock ];

  propagatedBuildInputs = [
    netifaces
    click
  ];

  meta = with lib; {
    description = "WS-Discovery implementation for python";
    homepage = "https://github.com/andreikop/python-ws-discovery";
    # TODO or lgpl3Only?
    license = licenses.lgpl3Plus;
    maintainers = with maintainers; [ felschr ];
  };
}
