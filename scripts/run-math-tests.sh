#!/bin/sh

# run case study
cd $HOME/racket-rtr-annotated-math/extra-pkgs/math/math-test/math/tests
rm -fr compiled
echo "running tests for math library with refinement types..."
$HOME/racket-rtr-annotated-math/bin/raco test *.rkt
