{
  description = "Unofficial Nix packaging for MiniMax Code";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      packages = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.callPackage ./package.nix { };
          minimax-code = pkgs.callPackage ./package.nix { };
        });

      overlays.default = final: prev: {
        minimax-code = final.callPackage ./package.nix { };
      };
    };
}
