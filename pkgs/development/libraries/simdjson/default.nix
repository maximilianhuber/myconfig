{ lib, stdenv, fetchFromGitHub, cmake }:

stdenv.mkDerivation rec {
  pname = "simdjson";
  version = "0.8.2";

  src = fetchFromGitHub {
    owner = "simdjson";
    repo = "simdjson";
    rev = "v${version}";
    sha256 = "sha256-azRuLB03NvW+brw7A/kbgkjoDUlk1p7Ch4zZD55QiMQ=";
  };

  nativeBuildInputs = [ cmake ];

  cmakeFlags = [
    "-DSIMDJSON_JUST_LIBRARY=ON"
  ] ++ lib.optional stdenv.hostPlatform.isStatic "-DSIMDJSON_BUILD_STATIC=ON";

  meta = with lib; {
    homepage = "https://simdjson.org/";
    description = "Parsing gigabytes of JSON per second";
    license = licenses.asl20;
    platforms = platforms.all;
    maintainers = with maintainers; [ chessai ];
  };
}
