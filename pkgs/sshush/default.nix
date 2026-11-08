{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
let
  version = "2.1.4";
in
(buildGoModule {
  name = "sshush";
  version = version;

  src = fetchFromGitHub {
    owner = "bencromwell";
    repo = "sshush";
    rev = "v${version}";
    sha256 = "sha256-b2579e74e1a4fba52eb85eff50a6ef2c7d9c30e2b9108f4678bf11c946fcd07a";
  };

  ldflags = [
    "-s" "-w"
    "-X main.version=${version}"
  ];

  meta = with lib; {
    description = "SSH config management from YAML files, with groups";
    homepage = "https://github.com/bencromwell/sshush";
    license = licenses.mit;
    maintainers = with maintainers; [bencromwell];
  };
})
