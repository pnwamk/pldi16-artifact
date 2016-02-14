#!/bin/sh

FILE1=$HOME/pldi16-artifact-misc/bitvector-redex-model/base-lang.rkt
FILE2=$HOME/pldi16-artifact-misc/bitvector-redex-model/subtype.rkt
FILE3=$HOME/pldi16-artifact-misc/bitvector-redex-model/well-typed.rkt


$HOME/racket-6.4/bin/drracket $FILE1 $FILE2 $FILE3
