#lang typed/racket

(require typed/safe/ops)

;; from section 4.4
(: sum-vector : (Vectorof Integer) -> Integer)
(define (sum-vector v)
  (for/sum ([i (in-range (vector-length v))])
    (safe-vector-ref v i)))