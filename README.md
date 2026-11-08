# nur

**My personal [NUR](https://github.com/nix-community/NUR) repository**

Packages are available under the `nur.repos.bencromwell` namespace, e.g.:

```nix
environment.systemPackages = with pkgs; [
  nur.repos.bencromwell.sshush
];
```

## Packages

- `sshush` — SSH config management from YAML files, with groups
- `git-spruce` — CLI for sprucing up your local git, cleans out branches that have been merged upstream (packaged in [pkgs/git-spruce](./pkgs/git-spruce), not yet enabled in [default.nix](./default.nix))
