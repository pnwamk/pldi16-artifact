#lang typed/racket

(: vec-ref :
(∀ (α) ((Vecof α) Int -> α)))
(define (vec-ref v i)
(if (≤ 0 i (sub1 (len v)))
       (unsafe-vec-ref v i)
       (error "invalid vector index!")))



(: safe-vec-ref :
(∀ (α) ([v : (Vecof α)]
   [i : (Refine [i : Int] (ď 0 i)
   (< i (len v)))] „> α)))
   (define (safe-vec-ref v i)
           (unsafe-vec-ref v i))

#|
;; does not typecheck:
 (: safe-dot-prod :
    (Vecof Int) (Vecof Int) -> Int)
  (define (safe-dot-prod A B)
   (for/sum ([i (in-range (len A))])
      (* (safe-vec-ref A i)
        (safe-vec-ref B i))))
|#

(define (vec-sum v)
(for/sum ([i (in-range (len v))])
(safe-vec-ref v i)))
