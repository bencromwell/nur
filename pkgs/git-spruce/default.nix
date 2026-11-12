{
  lib,
  git,
  buildGoModule,
  fetchFromGitHub,
}:
let
  version = "1.0.2";
  commit = "a4b7c031c08931d8789b993cb0e1b09d0f4d72fc";
in

(buildGoModule {
  pname = "git-spruce";
  inherit version;

  src = fetchFromGitHub {
    owner = "bencromwell";
    repo = "git-spruce";
    rev = "v${version}";
    sha256 = "sha256-Uaca+hFUbp1namjH6JiZccQTsxC2Vu7X1k8RyzRetIo=";
  };

  vendorHash = "sha256-tJgbxjSp5bqtS8jqoRRJkMFsQ3a3PWiPFBJHjXSSYKY=";

  # tests create git commits, which requires git and an identity in the sandbox
  nativeCheckInputs = [ git ];
  preCheck = ''
    export HOME="$TMPDIR"
    git config --global user.email "nix@localhost"
    git config --global user.name "Nix"
    git config --global init.defaultBranch "main"
  '';

  ldflags = [
    "-s" "-w"
    "-X main.version=${version}"
    "-X main.commit=${commit}"
  ];

  meta = with lib; {
    description = "CLI for sprucing up your local git, cleans out branches that have been merged upstream";
    homepage = "https://github.com/bencromwell/git-spruce";
    license = licenses.mit;
    maintainers = with maintainers; [bencromwell];
  };
})
