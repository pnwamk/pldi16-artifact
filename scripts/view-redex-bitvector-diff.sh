#!/bin/sh

ORIG=$HOME/pldi16-artifact-misc/base-redex-model
NEW=$HOME/pldi16-artifact-misc/bitvector-redex-model

meld $ORIG $NEW
