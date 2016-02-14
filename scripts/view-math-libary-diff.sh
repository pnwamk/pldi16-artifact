#!/bin/sh

ORIG=$HOME/racket-rtr/extra-pkgs/math/math-lib/
NEW=$HOME/racket-rtr-annotated-math/extra-pkgs/math/math-lib/

meld $ORIG $NEW
