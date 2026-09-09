{
  lib,
  nushell,
  writeText,
  writeTextFile,
}: let
  binDirs = packages: builtins.filter builtins.pathExists (map (pkg: "${lib.getBin pkg}/bin") packages);
  nuStringWithDeps = deps: content: ''
    # === : nix store dependencies
    $env.path ++= [
      ${lib.strings.join "\n\t" (binDirs deps)}
    ]

    # === : nushell code
    ${content}
  '';
  nuScript = {
    deps ? [],
    nuPkg ? nushell,
  }: text: ''
    #!${lib.getExe nuPkg} --no-config-file

    ${nuStringWithDeps deps text}
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

  name
  : Base filename. Normally include `.nu` extension here.

  textOrPath
  : Contents of script, or path to a script.

  *
  */
  writeNuText = {deps ? []}: name: textOrPath: writeText name (nuStringWithDeps deps (ensureText textOrPath));

  /**
  Create an executable Nushell script.

  > Incompatible reimplementation of [pkgs.writers.writeNu](https://github.com/NixOS/nixpkgs/blob/release-26.05/pkgs/build-support/writers/scripts.nix).

  # Arguments

  deps
  : Append dependencies from `nixpkgs` to scripts PATH.

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
    nuPkg ? nushell,
  }: name: textOrPath:
    writeTextFile {
      inherit name;
      executable = true;
      text = nuScript {inherit deps nuPkg;} (ensureText textOrPath);
    };

  /**
  Create an executable Nushell script, inside the derivations `/bin` -directory.

  > Incompatible reimplementation of [pkgs.writers.writeNuBin](https://github.com/NixOS/nixpkgs/blob/release-26.05/pkgs/build-support/writers/scripts.nix).

  # Arguments

  deps
  : Append dependencies from `nixpkgs` to scripts PATH.

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
    nuPkg ? nushell,
  }: name: textOrPath:
    writeTextFile {
      inherit name;
      executable = true;
      destination = "/bin/${name}";
      text = nuScript {inherit deps nuPkg;} (ensureText textOrPath);
    };
}
