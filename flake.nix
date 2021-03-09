{
  description = "Rsyslog container";

  inputs = {
    nixpkgs-unstable.url = "nixpkgs/nixpkgs-unstable";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    majordomo.url = "git+https://gitlab.intr/_ci/nixpkgs";
  };

  outputs = { self, nixpkgs-unstable, majordomo, ... }:
    let
      system = "x86_64-linux";
      pkgs-unstable = import nixpkgs-unstable { inherit system; };
    in {
      packages.x86_64-linux.container =
        import ./default.nix { nixpkgs = majordomo.outputs.nixpkgs; };

      defaultPackage.x86_64-linux = self.packages.x86_64-linux.container;

      packages.x86_64-linux.deploy = majordomo.outputs.deploy { tag = "webservices/rsyslog"; impure = true; };

      devShell.x86_64-linux = pkgs-unstable.mkShell {
        buildInputs = [ pkgs-unstable.nixUnstable ];
      };
    };
}
