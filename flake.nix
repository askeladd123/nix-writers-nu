{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  outputs = {nixpkgs, ...}: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    libUnscoped = import ./scripts.nix; # Raw functions, requires scope, use `pkgs.callPackage`.
    libFor = pkgs: pkgs.callPackage ./scripts.nix {}; # Provide your own `pkgs` and get functions.
  in {
    inherit libUnscoped libFor;
    libPinned = nixpkgs.lib.genAttrs supportedSystems (system: libFor nixpkgs.legacyPackages.${system}); # Functions are provided with specific version of `pkgs` for reproducibility.
  };
}
