{ lib, stdenv, xcbuild, darwin, liblogosdelivery, sealScript, cmdlineStub }:
# The sealed static liblogosdelivery the Makefile builds, from logos-delivery's
# own package: without RLN, and with only its C and kernel APIs global.
liblogosdelivery.overrideAttrs (old: {
  pname = "liblogosdelivery-sealed";

  nativeBuildInputs = old.nativeBuildInputs
    ++ lib.optionals stdenv.isDarwin [ darwin.cctools xcbuild ];

  postPatch = (old.postPatch or "") + ''
    cp ${cmdlineStub} library/delivery_cmdline.nim
    cat >> library/config.nims <<'EOF'
    switch("define", "disable_rln")
    switch("define", "useMalloc")
    switch("import", thisDir() & "/delivery_cmdline.nim")
    switch("passC", "-fno-common")
    const leopardX86 = when defined(amd64) or defined(i386): " -DCMAKE_CXX_FLAGS=-mssse3" else: ""
    switch("define", "LeopardCmakeFlags=-DCMAKE_BUILD_TYPE=Release -DENABLE_OPENMP=off" &
      " -DCOMPILER_SUPPORTS_MARCH_NATIVE=FALSE -DCMAKE_POSITION_INDEPENDENT_CODE=ON" & leopardX86)
    when defined(linux):
      switch("passC", "-fno-gnu-unique")
    EOF
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib $out/include
    bash ${sealScript} "logosdelivery_ waku_" "$NIMCACHE" $out/lib/liblogosdelivery.a
    cp library/liblogosdelivery.h library/liblogosdelivery_kernel.h $out/include/
    runHook postInstall
  '';

  postInstall = "";
})
