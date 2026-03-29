# nix check scope

- Narrowed `nix/package.nix` `checkPhase` to `test/overlay.bash`.
- Left `test/install.bash` and `test/uninstall.bash` as repository-level script tests rather
  than package-build checks because they exercise user-facing XDG mutation workflows, not the
  immutable Nix package output.
