{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      buildCommand = pkgs.writeShellApplication {
        name = "godoshi-build";
        runtimeInputs = [ pkgs.typst pkgs.coreutils pkgs.awscli2 pkgs.ruby pkgs.xpdf ];
        inheritPath = false;
        text = ''
          if [ -d ./results ]; then
            rm -r ./results
          fi
          ruby ./analysis.rb
          mkdir results
          typst compile --font-path ./fonts ./main.typ results/入稿データ.pdf
          typst compile --input "size=a4" --font-path ./fonts ./main.typ results/印刷プレビュー.pdf
          for author in white_green other_user; do
            mkdir -p results/authors/$author
            typst compile --input "size=a4" --input "out-author=$author" --font-path ./fonts ./main.typ results/authors/$author/印刷プレビュー.pdf
          done
          aws --endpoint-url "http://s3.internal" --no-sign-request s3 cp ./results s3://results/ --recursive
        '';
      };
      # ここに入れたファイルたちがexport対象になる
      demoSources = pkgs.runCommand "pdf-demo-sources" {} ''
        mkdir -p $out
        cp ${./main.typ} $out/main.typ
        cp ${./analysis.rb} $out/analysis.rb
        cp ${./flake.nix} $out/flake.nix
        cp ${./flake.lock} $out/flake.lock
        cp -r ${./authors} $out/authors
        cp -r ${./fonts} $out/fonts
      '';
      setupCommand = pkgs.writeShellApplication {
        name = "godoshi-setup";
        runtimeInputs = [ pkgs.coreutils pkgs.awscli2 ];
        inheritPath = false;
        text = ''
          cp -R --no-preserve=mode --update=none ${demoSources}/. "./"
          aws --endpoint-url "http://s3.internal" --no-sign-request s3 cp s3://resources/authors ./authors --recursive
        '';
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ buildCommand setupCommand ];
      };
      packages.${system} = {
        godoshi_setup = setupCommand;
        godoshi_build = buildCommand;
      };
    };
}
