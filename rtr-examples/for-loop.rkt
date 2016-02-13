#lang typed/racket

(require typed/safe/ops)

;; from section 4.4
(: sum-vector : (Vectorof Integer) -> Integer)
(define (sum-vector v)
  (for/sum ([i (in-range (vector-length v))])
    (safe-vector-ref v i)))

;; for loops expand into recursive functions
;; (as can be seen with the Macro Stepper above)
;; and our heuristic of guessing 'Index' for
;; variables used for vector accesses works well
;; for some loops (like the above) but not for
;; others (e.g. like if the iteration is toward
;; zero, since the last case i will be -1):

;; does not typecheck with our simple heuristic
#|
(: rev-sum-vector : (Vectorof Integer) -> Integer)
(define (rev-sum-vector v)
  (for/sum ([i (in-range (- (vector-length v) 1) 0 -1)])
    (safe-vector-ref v i)))
|#