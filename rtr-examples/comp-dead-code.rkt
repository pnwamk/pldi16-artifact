#lang typed/racket

;; illustrates unreachable code being correctly identified as such
;; via linear integer theory

(: dead< (-> (Refine [i : Integer] (< i 10)) Integer))
(define (dead< x)
  (if (< x 11)
      42
      "dead code"))

(: dead> (-> (Refine [i : Integer] (< i 10)) Integer))
(define (dead> x)
  (if (> 11 x)
      42
      "dead code"))

(: dead<= (-> (Refine [i : Integer] (< i 10)) Integer))
(define (dead<= x)
  (if (<= x 10)
      42
      "dead code"))

(: dead>= (-> (Refine [i : Integer] (< i 10)) Integer))
(define (dead>= x)
  (if (>= 10 x)
      42
      "dead code"))

(: dead= (-> (Refine [i : Integer] (< i 10)) Integer))
(define (dead= x)
  (if (= 10 x)
      "dead code"
      42))

(: dead2< (-> Integer Integer Integer))
(define (dead2< x y)
  (if (< x y)
      (if (< y x)
          "dead code"
          42)
      42))
