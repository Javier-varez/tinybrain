{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    dbt.url = "github:javier-varez/dbt/runOutOfNinja";
  };

  outputs =
    { nixpkgs, dbt, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      shellForSystem =
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.mkShellNoCC {
          packages = [
            dbt.packages.${system}.dbt
            pkgs.bluespec
            pkgs.gtkwave
            pkgs.probe-rs
            pkgs.flip-link
            pkgs.gcc-arm-embedded-14
            pkgs.qemu
          ];

        };

    in
    {
      devShell = forAllSystems shellForSystem;
    };
}
