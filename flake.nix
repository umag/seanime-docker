{
  description = "Seanime Docker Dev Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            goss
            container-structure-test
            bats
            hadolint
            jq
            curl
            git
          ];

          shellHook = ''
            echo "Seanime Docker Dev Environment Loaded"
            echo "Tools available: goss, container-structure-test, bats, hadolint"
          '';
        };
      }
    );
}
