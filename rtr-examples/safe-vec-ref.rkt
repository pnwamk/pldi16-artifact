#lang typed/racket

(require racket/unsafe/ops)

;; code from section 2.1 of paper

(define-type (Vecof A) (Vectorof A))
(define-type Int Integer)

(: safe-vec-ref :
   (∀ (α) (~> ([v : (Vecof α)]
               [i : (Refine [i : Int] (<= 0 i) (< i (len v)))])
              α)))
   (define (safe-vec-ref v i)
           (unsafe-vector-ref v i))


;; does not typecheck:
#|
(: almost-but-not-quite-safe-dot-prod :
   (Vecof Int) (Vecof Int) -> Int)
(define (almost-but-not-quite-safe-dot-prod A B)
  (for/sum ([i : (Refine [i : Natural] (< i (len A)))
               (in-range (vector-length A))])
    (* (safe-vec-ref A i)
       (safe-vec-ref B i)))) ;; B may be shorter than A!
|#

;; does typecheck!
(: safe-dot-prod :
   (~> ([A : (Vecof Int)]
        [B : (Refine [v : (Vecof Int)] (= (len v) (len A)))])
       Int))
(define (safe-dot-prod A B)
  (for/sum ([i : (Refine [i : Natural] (< i (len A)))
               (in-range (vector-length A))])
    (* (safe-vec-ref A i)
       (safe-vec-ref B i))))