#lang scribble/manual

@(require)

@title{Artifact: Occurrence Typing Modulo Theories}

This is a README for the artifact accompanying the
conditionally accepted paper "Occurrence Typing Modulo
Theories" (PLDI 2016).

@author{Andrew M. Kent, David Kempe, and Sam Tobin-Hochstadt}

This artifact provides examples of the following:

@itemlist[@item{An implementation of Refined Typed Racket
           (RTR) atop Typed Racket v6.2.1, including support
           for the theory of linear arithmetic and examples
           from the paper.}
          @item{A PLT Redex model of the λ@subscript{RTR}
           formal language found in the paper, along with a
           Redex model of the bitvector extension discussed
           in sections 2.2 and 3.4.}
          @item{Scripts which build and check for provably
           safe vector operations in the libraries our case
           study examined: math, plot, and pict3d.}
          @item{A modified version of the math library which
           uses refinement types in order to use more
           provably save vector operations throughout the
           library.}]


For detailed information see the sections below:

@section{Setting up the virtual machine}

TODO

@section{RTR Implementation}

TODO

@section{λ@subscript{RTR} PLT Redex Models}

TODO

@section{Case Study Scripts}

TODO

@section{Modified Math library}

TODO

