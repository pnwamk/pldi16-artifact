#!/bin/sh

ORIG=/home/dave/pldi16-artifact-misc/base-redex-model
NEW=/home/dave/pldi16-artifact-misc/bitvector-redex-model

meld $ORIG $NEW
