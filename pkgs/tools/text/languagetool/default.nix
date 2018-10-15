{ stdenv, fetchzip, jre, makeWrapper }:

stdenv.mkDerivation rec {
  name = "LanguageTool-${version}";
  version = "4.2";

  src = fetchzip {
    url = "https://www.languagetool.org/download/${name}.zip";
    sha256 = "01iy3cq6rwkm8sflj2nwp4ib29hyykd23hfsnrmqxji9csj8pf71";
  };
  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ jre ];

  installPhase = ''
    mkdir -p $out/share
    mv * $out/share/

    for lt in languagetool{,-commandline,-server};do
      makeWrapper ${jre}/bin/java $out/bin/$lt \
        --add-flags "-cp $out/share/ -jar $out/share/$lt.jar"
    done

    makeWrapper ${jre}/bin/java $out/bin/languagetool-http-server \
      --add-flags "-cp $out/share/languagetool-server.jar org.languagetool.server.HTTPServer"
  '';

  meta = with stdenv.lib; {
    homepage = https://languagetool.org;
    license = licenses.lgpl21Plus;
    maintainers = with maintainers; [
      edwtjo
      jgeerds
    ];
    description = "A proofreading program for English, French German, Polish, and more";
  };
}
