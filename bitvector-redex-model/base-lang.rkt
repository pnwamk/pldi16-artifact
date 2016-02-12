#lang racket

(require redex)
(provide (all-defined-out)) 


;; ---------------------------------------------------------
;; Definition for Base Refinement-Typed Racket
(define-language RTR-Base
  [x y z ::= variable-not-otherwise-mentioned]
  [n ::= integer]
  [b ::= true false]
  ;; bitvector specific values--base elements (sans objects) grammar:
  [bv ::= (bv63 n)]
  ;; bitvector specific values--inductive constructors grammar:
  [bvbop ::= bvand bvor bvadd bvsub bvxor bvmul bv= bv<=]
  [p ::= int? bool? pair? not + - * <= fst snd pair bvbop bvnot]
  [v ::= n p bv true false (cons v v) (closure ρ ([x : T] ...) e)]
  [e ::= v x (e e ...) (if e e e) (λ ([x : T] ...) e) (let ([x e]) e)]
  [field ::= first second]
  [path :: (field ...)]
  [o ::= x (field o)]
  [T S ::= Any True False Int BV (U T ...) (Fun ([x : T] ...) -> Res)
     (Pair T S) (Refine ([x : T]) P) (∃ ([x : T] ...) T)]
  [Res ::= (Result T P Q)]
  [A ::= (@ o T) X]
  [P Q R ::= A (¬ P) (And P ...) (Or P ...) TT FF (↦ x o)
     (∃ ([x : T] ...) P)]
  [Γ  ::= {[x : T] ...}]
  [Ψ  ::= {P ...}]
  [Δ  ::= (Env Γ Ψ)]
  [± ::= pos neg]
  ;; bitvector specific value set grammar:
  [BV-VAL ::= bv o (bvnot BV-VAL) (bvbop BV-VAL BV-VAL)]
  ;; bitvector specific formula grammar:
  [X ::= (bv= BV-VAL BV-VAL) (bv<= BV-VAL BV-VAL)]
  ;; our only external theory is a bitvector theory (w/ 63 bit bitvectors)
  [TH ::= BV63]
  [ρ ::= ([x v] ...)]
  #:binding-forms
  (λ ([x : T] ...) e #:refers-to (shadow x ...))
  (let ([x e_x]) e #:refers-to x)
  (Fun ([x : T] ...) -> Res #:refers-to (shadow x ...))
  (Refine ([x : T]) P #:refers-to x)
  (∃ ([x : T] ...) any #:refers-to (shadow x ...))
  (closure ρ ([x : T] ...) e #:refers-to (shadow x ...))) 


;; ---------------------------------------------------------
;; #lang racket predicates
(define x? (redex-match? RTR-Base x))
(define X? (redex-match? RTR-Base X))
(define p? (redex-match? RTR-Base p))
(define e? (redex-match? RTR-Base e))
(define bvbop? (redex-match RTR-Base bvbop))
(define field? (redex-match? RTR-Base field))
(define path? (redex-match? RTR-Base path))
(define o? (redex-match? RTR-Base o))
(define T? (redex-match? RTR-Base T))
(define U? (redex-match? RTR-Base (U T ...)))
(define P? (redex-match? RTR-Base P))
(define type-env? (redex-match? RTR-Base Γ))
(define prop-env? (redex-match? RTR-Base Ψ))
(define env? (redex-match? RTR-Base Δ))
(define OfType? (redex-match? RTR-Base (@ o T)))
(define ((OfType*? type-pred?) x)
  (and (OfType? x)
       (type-pred? (third x))))
(define Atom? (redex-match? RTR-Base A))
(define Not? (redex-match? RTR-Base (¬ any)))
(define NotOfType? (redex-match? RTR-Base (¬ (@ o T))))
(define Alias? (redex-match? RTR-Base (↦ x o)))
(define And? (redex-match? RTR-Base (And P ...)))
(define Or? (redex-match? RTR-Base (Or P ...)))
(define TT? (redex-match? RTR-Base TT))
(define FF? (redex-match? RTR-Base FF))
(define Refine? (redex-match? RTR-Base (Refine ([_ : _]) _)))
(define Exists? (redex-match? RTR-Base (∃ ([x : T] ...) any)))
(define Fun? (redex-match? RTR-Base (Fun ([x : T] ...) -> Res)))
(define Bot? (redex-match? RTR-Base (U)))
(define Any? (redex-match? RTR-Base Any))

(define-term Byte
  (Refine ([x : BV]) (And (bv<= (bv63 0) x) (bv<= x (bv63 255)))))
(define-term Nibble
  (Refine ([x : BV]) (And (bv<= (bv63 0) x) (bv<= x (bv63 127)))))
