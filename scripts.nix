{
  lib,
  nushell,
  writeText,
  writeTextFile,
}: let
  binDirs = packages: builtins.filter builtins.pathExists (map (pkg: "${lib.getBin pkg}/bin") packages);
  nuStringWithCtx = {
    deps ? [],
    libs ? [],
    plugins ? [],
  }: content:
    lib.concatStringsSep "\n\n" (
      builtins.filter (s: s != "") [
        (lib.optionalString (deps != [] || libs != [] || plugins != []) ''
          # === : nix store dependencies
        '')

        (lib.optionalString (deps != []) ''
          $env.path ++= [
            ${lib.concatStringsSep "\n\t" (binDirs deps)}
          ]
        '')

        (lib.optionalString (libs != []) ''
          const NU_LIB_DIRS = [
            ${lib.concatStringsSep "\n\t" libs}
          ]
        '')

        (lib.optionalString (plugins != []) ''
          const NU_PLUGIN_DIRS = [
            ${lib.concatStringsSep "\n\t" plugins}
          ]
        '')

        ''
          # === : nushell code
          ${content}
        ''
      ]
    );
  nuScript = {
    deps ? [],
    libs ? [],
    plugins ? [],
    nuPkg ? nushell,
  }: text: ''
    #!${lib.getExe nuPkg} --no-config-file
    ${nuStringWithCtx {inherit deps libs plugins;} text}
  '';
  ensureText = maybePath:
    if builtins.isPath maybePath
    then builtins.readFile maybePath
    else if builtins.isString maybePath
    then maybePath
    else throw "expected path or string, found ${builtins.typeOf maybePath}";
in {
  /**
  Create a text file where dependencies are added in Nushell syntax.

  # Arguments

  deps
  : Append dependencies from `nixpkgs` to scripts PATH.

  libs
  : Nushell modules that will be searched by `use` statements.

  plugins
  : Add plugins to file.

  name
  : Base filename. Normally include `.nu` extension here.

  textOrPath
  : Contents of script, or path to a script.

  *
  */
  writeNuText = {
    deps ? [],
    libs ? [],
    plugins ? [],
  }: name: textOrPath: writeText name (nuStringWithCtx {inherit deps libs plugins;} (ensureText textOrPath));

  /**
  Create an executable Nushell script.

  > Incompatible reimplementation of [pkgs.writers.writeNu](https://github.com/NixOS/nixpkgs/blob/release-26.05/pkgs/build-support/writers/scripts.nix).

  # Arguments

  deps
  : Append dependencies from `nixpkgs` to scripts PATH.

  libs
  : Nushell modules that will be searched by `use` statements.

  plugins
  : Add plugins to file.

  nuPkg
  : Which Nushell package to use as interpreter.

  name
  : Base filename for script.

  textOrPath
  : Nushell code string, or path to a script.
  *
  */
  writeNu = {
    deps ? [],
    libs ? [],
    plugins ? [],
    nuPkg ? nushell,
  }: name: textOrPath:
    writeTextFile {
      inherit name;
      executable = true;
      text = nuScript {inherit deps libs plugins nuPkg;} (ensureText textOrPath);
    };

  /**
  Create an executable Nushell script, inside the derivations `/bin` -directory.

  > Incompatible reimplementation of [pkgs.writers.writeNuBin](https://github.com/NixOS/nixpkgs/blob/release-26.05/pkgs/build-support/writers/scripts.nix).

  # Example

  ```nix
  writeNuBin { deps = [pkgs.ripgrep]; } "format-matches" ''
    def main [regexp: string]: any -> list<string> {
      rg --json --regexp $regexp | lines | each { from json } | where type == 'match' | get data | each {|i| $'($i.path.text):($i.line_number)' }
    }
  '';
  ```

  # Arguments

  deps
  : Append dependencies from `nixpkgs` to scripts PATH.

  libs
  : Nushell modules that will be searched by `use` statements.

  plugins
  : Add plugins to file.

  nuPkg
  : Which Nushell package to use as interpreter.

  name
  : Base filename for script. This is the command you will be runnig.

  textOrPath
  : Nushell code string, or path to a script.
  *
  */
  writeNuBin = {
    deps ? [],
    libs ? [],
    plugins ? [],
    nuPkg ? nushell,
  }: name: textOrPath:
    writeTextFile {
      inherit name;
      executable = true;
      destination = "/bin/${name}";
      text = nuScript {inherit deps libs plugins nuPkg;} (ensureText textOrPath);
    };
}
