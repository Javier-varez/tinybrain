{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    dbt.url = "github:javier-varez/dbt";
  };

  outputs =
    { nixpkgs, dbt, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      shell = pkgs.mkShellNoCC {
        packages = [
          dbt.packages.${system}.dbt
          pkgs.bluespec
          pkgs.gtkwave
        ];
      };
    in
    {
      devShells.${system}.default = shell;
    };
}
