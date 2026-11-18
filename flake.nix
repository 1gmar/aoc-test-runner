{
  description = "AOC test runner";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixvim-1gmar = {
      url = "github:1gmar/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixvim-1gmar,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      neovim = nixvim-1gmar.packages.${system}.default.extend {
        git.enable = true;
        languages = {
          nushell.enable = true;
        };
      };
      checkScript =
        name: script:
        pkgs.runCommandLocal name { nativeBuildInputs = [ pkgs.nushell ]; } ''
          set -e
          nu -n --no-std-lib -c '
            let errors = nu -n --ide-check 10 ${script}
              | lines
              | each { from json }
              | where severity? == Error
            if ($errors | is-not-empty) {
              $errors | to json -r | print -e
              exit 1
            }
          '
          touch $out
        '';
    in
    {
      checks.${system} = {
        run-tests = checkScript "run-tests" ./run-tests.nu;
        test-utils = checkScript "test-utils" ./modules/test-utils.nu;
      };
      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = [
          neovim
          pkgs.nushell
        ];
      };
      packages.${system}.default =
        pkgs.writers.writeNuBin "run-tests" # nu
          ''
            def main [testPattern: string = '^day\d\d? test' --ignored (-i)] {
              [
                "use tests * ;"
                "use ${./run-tests.nu} * ;"
                "scope commands"
                $"| run-test-runner (if $ignored { '-i' }) '($testPattern)'"
              ] 
              | str join (char space)
              | with-env {NU_LIB_DIRS: ($env.NU_LIB_DIRS | str join (char env_sep))} { nu -n -c $in }
            }
          '';
      modules = ./modules;
    };
}
