
> This is currently a document for planning

Rewrite of the `pkgs.writers` Nushell writers.

Advantages:
- ergonomics: `deps` parameter, where you can specify binaries for the script `PATH` directly
- implementation: write directly in Nushell, instead of using `makeWrapper` that creates a Bash script. 
  - potentially faster and more readable
- compatible: `writeNuText` can be sourced as a configuration file in Nu, with correct dependencies, which is not possible with a Bash wrapped script

## nix structure

Use `flake-parts` to deal with system.

Make files with boundaries defined as parameters, and run with `callPackage`. Expose to flake all these outputs:
- locked library: pinned to current flake revision
- open library: pass your own version of `nixpkgs`
- open function: pass your own boundary functions instead

I am unsure of which approach that is best, but I like these at least.
