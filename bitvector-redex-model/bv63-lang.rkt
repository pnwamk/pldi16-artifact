#lang racket

(require redex
         "base-lang.rkt"
         "subtype.rkt")

(define-extended-language RTR-BV63
  RTR-Base
  [bv ::= (bv63 n)]
  [v ::= .... bv]
  [bvbop ::= .... bv63+ bv63- bv63*
     bv63or bv63and bv63sle bv63zero?]
  [p ::= .... bvbop bvnot]
  [BV ::= bv x (bvnot BV) (bvbop BV BV)]
  [X ::= (BV63= BV BV) (BV63<= BV BV)]
  [TH ::= BV63])

(define-metafunction/extension free-vars lc-num-lang
  free-vars-num : e -> (x ...)
  [(free-vars-num number)
   ()]
  [(free-vars-num (+ e_1 e_2))
   (∪ (free-vars-num e_1)
      (free-vars-num e_2))])

#|

(simplify (bvadd #x07 #x03)) ; addition
(simplify (bvsub #x07 #x03)) ; subtraction
(simplify (bvneg #x07)) ; unary minus
(simplify (bvmul #x07 #x03)) ; multiplication
(simplify (bvurem #x07 #x03)) ; unsigned remainder
(simplify (bvsrem #x07 #x03)) ; signed remainder
(simplify (bvsmod #x07 #x03)) ; signed modulo
(simplify (bvshl #x07 #x03)) ; shift left
(simplify (bvlshr #xf0 #x03)) ; unsigned (logical) shift right
(simplify (bvashr #xf0 #x03)) ; signed (arithmetical) shift right
Bitwise Operations

load in editor
(simplify (bvor #x6 #x3))   ; bitwise or
(simplify (bvand #x6 #x3))  ; bitwise and
(simplify (bvnot #x6)) ; bitwise not
(simplify (bvnand #x6 #x3)) ; bitwise nand
(simplify (bvnor #x6 #x3)) ; bitwise nor
(simplify (bvxnor #x6 #x3)) ; bitwise xnor

(simplify (bvsle #x0a #xf0))  ; signed less or equal
(simplify (bvslt #x0a #xf0))  ; signed less than
(simplify (bvsge #x0a #xf0))  ; signed greater or equal
(simplify (bvsgt #x0a #xf0))  ; signed greater than

|#