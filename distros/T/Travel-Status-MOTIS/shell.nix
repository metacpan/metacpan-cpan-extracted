{ pkgs ? import <nixpkgs> {} }: pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    (perl.withPackages (perlPackages: with perlPackages; [
      ModuleBuild
      ClassAccessor
      DateTime
      DateTimeFormatISO8601
      JSON
      LWPProtocolHttps
      LWPUserAgent
      TestCompile
      TestPod
      URI
      FileSlurp
    ]))
  ];
}
