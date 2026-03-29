{ lib, stdenvNoCC, bash }:

stdenvNoCC.mkDerivation {
  pname = "direnv-overlay";
  version = "0.1.0";

  src = lib.cleanSource ../.;

  nativeBuildInputs = [ bash ];

  doCheck = true;

  checkPhase = ''
    runHook preCheck

    bash test/overlay.bash

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 lib/direnv-overlay.sh \
      $out/share/direnv/lib/direnv-overlay.sh
    install -Dm644 README.md \
      $out/share/doc/direnv-overlay/README.md

    runHook postInstall
  '';

  meta = with lib; {
    description = "Keep personal direnv overlays out of upstream repositories";
    homepage = "https://github.com/BeLeap/direnv-overlay";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
