#lang racket

(require redex
         "base-lang.rkt")

(provide BV63-proves?)

;; redex-prop grammar
;; [BV-VAL ::= bv o (bvnot BV-VAL) (bvbop BV-VAL BV-VAL)]
;; [X ::= (bv= BV-VAL BV-VAL) (bv<= BV-VAL BV-VAL)]
#|
[(theory-of (¬ X)) (theory-of X)]
  [(theory-of (= BV-VAL BV-VAL)) BV63]
  [(theory-of (<= BV-VAL BV-VAL)) BV63]
  [(theory-of (And P ...))
   BV63
   (where (BV63 ...) ((theory-of P) ...))]
  [(theory-of (Or P ...))
   BV63
   (where (BV63 ...) ((theory-of P) ...))]
  [(theory-of any) BASE-THEORY])
|#

;; redex->z3
;; redex-prop mutable-id-hash -> string
;; - the input hash is the set of objects in the
;;    initial redex props and their corresponding
;;    z3 variables (as strings)
;; - the output string is a z-3 assertion
(define ((redex->z3 ids) prop)
  ;; generator of fresh z3-friendly ids (as a string)
  (define (fresh-id o)
    (symbol->string
     (variable-not-in (hash-values ids)
                      (if (symbol? o) o (gensym 'o)))))
  ;; return the logical statement as a string
  (let ->z3 ([prop prop])
    (match prop
      [`(bv= ,lhs ,rhs)
       (~a "(= " (->z3 lhs) " " (->z3 rhs) ")")]
      [`(bv<= ,lhs ,rhs)
       (~a "(bvsle " (->z3 lhs) " " (->z3 rhs) ")")]
      [`(¬ ,p) (~a "(not " (->z3 p) ")")]
      [`(,(? bvbop? op) ,lhs ,rhs)
       (~a "(" (symbol->string op) " " (->z3 lhs) " " (->z3 rhs) ")")]
      [`(bvnot ,p) (~a "(bvnot " (->z3 p) ")")]
      [`(And . ,ps)
       (apply string-append "(and "
              (append (map ->z3 ps) (list ")")))]
      [`(Or . ,ps)
       (apply string-append "(or "
              (append (map ->z3 ps) (list ")")))]
      [(? o? o)
       (hash-ref! ids o (λ _ (fresh-id o)))]
      [`(bv63 ,(? exact-integer? n))  (~a "(_ bv" n " 63)")]
      [else (error '->z3 "unrecognized term: ~a\n" else)])))



(define (BV63-proves? redex-assumptions redex-goal)
  ;; build up the query
  (define id-hash (make-hash))
  (define assumptions
    (map (redex->z3 id-hash) redex-assumptions))
  (define goal ((redex->z3 id-hash) redex-goal))
  ;; call z3
  (match-define (list inp outp pid errp cmd)
    (process "z3 -in"))
  ;; send variable declarations to z3
  (for ([var (in-hash-values id-hash)])
    ;(printf "(declare-const ~a (_ BitVec 63))\n" var)
    (fprintf outp "(declare-const ~a (_ BitVec 63))" var))
  ;; send assertions to z3
  (for ([fact (in-list assumptions)])
    ;(printf "(assert ~a)\n" fact)
    (fprintf outp "(assert ~a)" fact))
  ;(printf "(assert (not ~a))" goal)
  (fprintf outp "(assert (not ~a))" goal)
  ;; check for satisfiability
  (fprintf outp "(check-sat)")
  (close-output-port outp)
  (close-input-port errp)
  (define result (read inp))
  (close-input-port inp)
  (cmd 'kill)
  (match result
    ['sat #f]
    ['unsat #t]
    [else (error 'BV63-proves? "result was ~a\n" else)]))

