#lang typed/racket
(require typed/safe/ops)

(define-type (Vec a) (Vectorof a))
(define-type Int Integer)
(define-type Nat Natural)

(define-syntax-rule (Mref M r c)
  (safe-vector-ref (safe-vector-ref M r) c))

(define-syntax-rule (Mset! M r c val)
  (safe-vector-set! (safe-vector-ref M r) c val))

(define safe-vref safe-vector-ref)

;; A[m×n] * B[n×p] = C[m×p]) 
(: matrix*
   (~> ([A : (Vec (Refine [a : (Vec Int)] (= (len a) n)))]
        [B : (Vec (Refine [b : (Vec Int)] (= (len b) p)))]
        [C : (Vec (Refine [c : (Vec Int)] (= (len c) p)))]
        [m : (Refine [x : Nat] (= x (len A) (len C)))]
        [n : (Refine [y : Nat] (= y (len B)))]
        [p : Nat])
       Void))
(define (matrix* A B C m n p)
  (for* ([i : (Refine [x : Nat] (< x m))
            (in-range m)]
         [j : (Refine [y : Nat] (< y p))
            (in-range p)])
    (define Cij-val : Int
      (for/sum ([k : (Refine [z : Nat] (< z n))
                   (in-range n)])
        (+ (Mref A i k) (Mref B k j))))
    (Mset! C i j Cij-val)))
