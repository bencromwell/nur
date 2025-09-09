{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
let
  version = "2.1.1";
in
(buildGoModule {
  name = "sshush";
  version = version;

  src = fetchFromGitHub {
    owner = "bencromwell";
    repo = "sshush";
    rev = "v${version}";
    sha256 = "sha256-scsn09pUVm/rf2/0FgWt2hc7/tUjiVSPH7JiaTREwhw=";
  };

  vendorHash = "sha256-6zvwxTwkIBdJ39fpaGpUmY59VGXsxEPwnq67Yf+jTGg=";

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
