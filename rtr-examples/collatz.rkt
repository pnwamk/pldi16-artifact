#lang typed/racket

;; From Refinement Types for Haskell
;; by Vazou et al.

(: collatz (-> Integer (Refine [i : Integer] (= i 1))))
(define (collatz int)
  (cond
    [(= int 1) 1]
    [(even? int) (collatz (quotient int 2))]
    [else (collatz (+ (* int 3) 1))]))
