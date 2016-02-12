#lang scribble/manual


@title{Artifact: Occurrence Typing Modulo Theories}

@author{Andrew M. Kent, David Kempe, and Sam Tobin-Hochstadt}

This is a README for the artifact accompanying the
conditionally accepted paper "Occurrence Typing Modulo
Theories" (PLDI 2016).

This artifact provides examples of the following:

@itemlist[@item{An implementation of Refined Typed Racket
           atop Typed Racket v6.2.1, including support for
           the theory of linear arithmetic.}
          @item{A PLT Redex model of the λ@subscript{RTR}
           formal language found in our conditionally
           accepted paper, along with a Redex model of the
           bitvector extension discussed in sections 2.2 and
           3.4.}
          @item{Scripts which typecheck and attempt to
           verify all vector operations in the libraries our
           case study examined: math, plot, and pict3d.}
          @item{A modified version of the math library
           which uses refinement types in order to use more
           provably save vector operations.}]


For instructions setting up the virtual machine, see TODO.