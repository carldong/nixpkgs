{ stdenv, fetchFromGitHub, erlang, makeWrapper, coreutils, bash, beamPackages }:

let
  inherit (beamPackages) buildRebar3 buildHex;
  proper = buildHex rec {
    name    = "proper";
    version = "1.1.1-beta";
    sha256  = "0hnkhs761yjynw9382w8wm4j3x0r7lllzavaq2kh9n7qy3zc1rdx";

    configurePhase = ''
      ${erlang}/bin/escript write_compile_flags include/compile_flags.hrl
    '';
  };
in
buildRebar3 rec {
  name    = "lfe";
  version = "1.2.1";

  src = fetchFromGitHub {
    owner  = "rvirding";
    repo   = name;
    rev    = version;
    sha256 = "0j5gjlsk92y14kxgvd80q9vwyhmjkphpzadcswyjxikgahwg1avz";
  };

  buildInputs = [ makeWrapper ];
  beamDeps    = [ proper ];
  patches     = [ ./no-test-deps.patch ];
  doCheck     = true;
  checkTarget = "travis";

  # These installPhase tricks are based on Elixir's Makefile.
  # TODO: Make, upload, and apply a patch.
  installPhase = ''
    local libdir=$out/lib/lfe
    local ebindir=$libdir/ebin
    local bindir=$libdir/bin

    rm -Rf $ebindir
    install -m755 -d $ebindir
    install -m644 _build/default/lib/lfe/ebin/* $ebindir

    install -m755 -d $bindir
    for bin in bin/lfe{,c,doc,script}; do install -m755 $bin $bindir; done

    install -m755 -d $out/bin
    for file in $bindir/*; do ln -sf $file $out/bin/; done
  '';

  # Thanks again, Elixir.
  postFixup = ''
    # LFE binaries are shell scripts which run erl and lfe.
    # Add some stuff to PATH so the scripts can run without problems.
    for f in $out/bin/*; do
      wrapProgram $f \
        --prefix PATH ":" "${stdenv.lib.makeBinPath [ erlang coreutils bash ]}:$out/bin"
      substituteInPlace $f --replace "/usr/bin/env" "${coreutils}/bin/env"
    done
  '';

  meta = with stdenv.lib; {
    description     = "The best of Erlang and of Lisp; at the same time!";
    longDescription = ''
      LFE, Lisp Flavoured Erlang, is a lisp syntax front-end to the Erlang
      compiler. Code produced with it is compatible with "normal" Erlang
      code. An LFE evaluator and shell is also included.
    '';

    homepage     = "http://lfe.io";
    downloadPage = "https://github.com/rvirding/lfe/releases";

    license      = licenses.asl20;
    maintainers  = with maintainers; [ yurrriq ];
    platforms    = platforms.unix;
  };
}
