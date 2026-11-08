# nur

**My personal [NUR](https://github.com/nix-community/NUR) repository**

This repo is not registered in the community NUR yet, so the
`nur.repos.bencromwell.*` namespace is not available. Until it is, use it
directly as a flake input:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nur = {
      url = "github:bencromwell/nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nur, ... }: {
    nixosConfigurations.host = nixpkgs.lib.nixosSystem {
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [
            nur.legacyPackages.${pkgs.stdenv.hostPlatform.system}.sshush
          ];
        })
      ];
    };
  };
}
```

Or in a Home Manager / devshell flake, add the same input and reference
`nur.legacyPackages.${system}.sshush` in `home.packages` / `packages`.

Without flakes, import the repo directly (uses the top-level `default.nix`):

```nix
# configuration.nix / packageOverrides
let
  nur = import (builtins.fetchTarball "https://github.com/bencromwell/nur/archive/main.tar.gz") { inherit pkgs; };
in
environment.systemPackages = [ nur.sshush ];
```

or as a nixpkgs overlay via the top-level [overlay.nix](./overlay.nix):

```nix
nixpkgs.overlays = [ (import (builtins.fetchTarball "https://github.com/bencromwell/nur/archive/main.tar.gz") + "/overlay.nix") ];
# then: environment.systemPackages = [ pkgs.sshush ];
```

For local development: `nix-build -A sshush` or `nix build .#sshush` from
this repo.

## Packages

- `sshush` — SSH config management from YAML files, with groups
- `git-spruce` — CLI for sprucing up your local git, cleans out branches that have been merged upstream (packaged in [pkgs/git-spruce](./pkgs/git-spruce), not yet enabled in [default.nix](./default.nix))
