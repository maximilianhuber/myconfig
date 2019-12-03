{ stdenv, lib, buildPythonPackage, fetchPypi, python, isPy27
, dotnet-sdk
, substituteAll
, distro
, unzip
}:

buildPythonPackage rec {
  pname = "dotnetcore2";
  version = "2.1.11";
  format = "wheel";
  disabled = isPy27;

  src = fetchPypi {
    inherit pname version format;
    python = "py3";
    platform = "manylinux1_x86_64";
    sha256 = "a335fb0abdaaeee7ba128b81b5350adfc5d2b2adf6a64cbc4d1a3b7cdf8560da";
  };

  nativeBuildInputs = [ unzip ];

  propagatedBuildInputs = [ distro ];

  # needed to apply patches
  prePatch = ''
    unzip dist/dotnet*
  '';

  patches = [
    ( substituteAll {
        src = ./runtime.patch;
        dotnet = dotnet-sdk;
      }
    )
  ];

  # unfortunately the noraml pip install fails because the manylinux1 format check fails with NixOS
  installPhase = ''
    mkdir -p $out/${python.sitePackages}/${pname}
    # copy metadata
    cp -r dotnetcore2-2* $out/${python.sitePackages}
    # copy non-dotnetcore related files
    cp -r dotnetcore2/{__init__.py,runtime.py} $out/${python.sitePackages}/${pname}
  '';

  # no tests, ensure it's one useful function works
  checkPhase = ''
    ${python.interpreter} -c 'from dotnetcore2 import runtime; print(runtime.get_runtime_path())'
  '';

  meta = with lib; {
    description = "DotNet Core runtime";
    homepage = "https://github.com/dotnet/core";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ jonringer ];
  };
}
