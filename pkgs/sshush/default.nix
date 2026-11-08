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
    sha256 = "sha256-PS0zF3lLJckwfmmw3ETcomTu4TGeE4j80eH6wcl/wbQ=";
  };

  vendorHash = "sha256-FmNqoJ28v4rSd/1yrWBSKC80eefc4ZCNPktlV9IkP78=";

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
