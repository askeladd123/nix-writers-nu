
> This is currently a document for planning

Rewrite of the `pkgs.writers` Nushell writers.

Advantages:
- ergonomics: `deps` parameter, where you can specify binaries for the script `PATH` directly
- implementation: write directly in Nushell, instead of using `makeWrapper` that creates a Bash script. 
  - potentially faster and more readable
- compatible: `writeNuText` can be sourced as a configuration file in Nu, with correct dependencies, which is not possible with a Bash wrapped script

Usage: see `./flake.nix` comments for output documentation. I could not decide on the best way to expose functions, so I chose 3.
