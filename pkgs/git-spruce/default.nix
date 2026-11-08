{
  lib,
  git,
  buildGoModule,
  fetchFromGitHub,
}:
let
  version = "0.3.0";
  commit = "44b8354c2bdb9813876e4ba4ae1953df4e77a30a";
in

(buildGoModule {
  pname = "git-spruce";
  inherit version;

  src = fetchFromGitHub {
    owner = "bencromwell";
    repo = "git-spruce";
    rev = "v${version}";
    sha256 = "sha256-guN+hX6CmMD7L20QgGPepl4nWN9sV3RlkUgJDBYuyhE=";
  };

  vendorHash = "sha256-POgXUoq3LtX7hy0rZihiC0Ci9U0s/CP8c/VW2T5sH/U=";

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
