{ buildPecl, lib, pkg-config, libyaml }:

buildPecl {
  pname = "yaml";

  version = "2.2.1";
  sha256 = "sha256-4XrQTnUuJf0Jm93S350m3+8YPI0AxBebydei4cl9eBk=";

  configureFlags = [ "--with-yaml=${libyaml}" ];

  nativeBuildInputs = [ pkg-config ];

  meta.maintainers = lib.teams.php.members;
}
