#lang racket

(require redex
         "base-lang.rkt")

(define-extended-language RTR-BV32
  RTR-Base
  [v ::= .... (bv32 n)]
  [p ::= .... bv32+ bv32- bv32* bv32<=])