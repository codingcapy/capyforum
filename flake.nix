{
  description = "Flake for bun project with aarch64 and linux targets";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable2.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixpkgs-unstable2 }:
    let
      systems = [ "x86_64-linux" "aarch64-darwin" ];
    in
    {
      devShell = builtins.listToAttrs (map
        (system: {
          name = system;
          value =
            let
              pkgs = nixpkgs.legacyPackages.${system};
              unstable = nixpkgs-unstable.legacyPackages.${system};
              unstable2 = nixpkgs-unstable2.legacyPackages.${system}; in
            pkgs.mkShell {
              buildInputs = with pkgs; [
                gcc.cc.lib
                nodejs_20
                unstable.bun
                playwright
                concurrently
                playwright-driver.browsers
                yarn
                act
                gh
                unstable2.gleam
                unstable.inotify-tools
                unstable.erlang_28
                unstable.beam27Packages.rebar3
                unstable.tailwindcss_4
              ];


              shellHook = ''
                export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib.outPath}/lib:$LD_LIBRARY_PATH"
                export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
                export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
              '';
            };
        })
        systems);
    };
}

