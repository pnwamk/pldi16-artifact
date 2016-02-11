#lang racket

(require redex
         "base-lang.rkt"
         "base-helpers.rkt"
         "subtype.rkt"
         "subtype-helpers.rkt"
         "well-typed.rkt"
         redex-chk)


(define-metafunction RTR-Base
  plus : n n -> n
  [(plus n_1 n_2) ,(+ (term n_1) (term n_2))])

(define-metafunction RTR-Base
  minus : n n -> n
  [(minus n_1 n_2) ,(- (term n_1) (term n_2))])

(define-metafunction RTR-Base
  mult : n n -> n
  [(mult n_1 n_2) ,(* (term n_1) (term n_2))])

(define-judgment-form RTR-Base
  #:mode (leq I I)
  #:contract (leq n n)
  [(where #t ,(<= (term n_1) (term n_2)))
   ------------------
   (leq n_1 n_2)])


;; ---------------------------------------------------------
;; overlap tests
(define-metafunction RTR-Base
  δ : p v ... -> v
  [(δ int? n) true]
  [(δ int? v) false]

  [(δ bool? true) true]
  [(δ bool? false) true]
  [(δ bool? v) false]

  [(δ pair? (cons v_1 v_2)) true]
  [(δ pair? v) false]

  [(δ not false) true]
  [(δ not v) false]

  [(δ + n_1 n_2) (plus n_1 n_2)]
  
  [(δ - n_1 n_2) (minus n_1 n_2)]
  
  [(δ * n_1 n_2) (mult n_1 n_2)]

  [(δ <= n_1 n_2)
   true
   (judgment-holds (leq n_1 n_2))]
  [(δ <= n_1 n_2) false]

  [(δ fst (cons v_1 v_2)) v_1]

  [(δ snd (cons v_1 v_2)) v_2]

  [(δ pair v_1 v_2) (cons v_1 v_2)])


(define-metafunction RTR-Base
  ext-ρ : ρ [x := v] ... -> ρ
  [(ext-ρ ([y v_y] ...) [x := v] ...)
   ([x v] ... [y v_y] ...)])

(define-judgment-form RTR-Base
  #:mode (valof I I O)
  #:contract (valof ρ e v)

  [(where v (lookup ρ x))
   ---------------------- "B-Var"
   (valof ρ x v)]

  [(valof ρ e_f p)
   (valof ρ e_a v_a) ...
   (where v (δ p v_a ...))
   ---------------------- "B-Delta"
   (valof ρ (e_f e_a ...) v)]

  [(valof ρ e_x v_x)
   (valof (ext-ρ ρ [x := v_x]) e v)
   ---------------------- "B-Let"
   (valof ρ (let ([x e_x]) e) v)]

  [(valof ρ v v) "B-Val"]

  [(valof ρ (λ ([x : T] ...) e) (closure ρ ([x : T] ...) e)) "B-Abs"]

  [(valof ρ e_f (closure ρ_c ([x : T] ...) e_c))
   (valof ρ e_a v_a) ...
   (valof (ext-ρ ρ [x := v_a] ...) e_c v)
   ---------------------------- "B-Beta"
   (valof ρ (e_f e_a ...) v)]

  [(valof ρ e_1 v_1) (<> v_1 false)
   (valof ρ e_2 v)
   ---------------------------- "B-IfTrue"
   (valof ρ (if e_1 e_2 e_3) v)]

  [(valof ρ e_1 false) (valof ρ e_3 v)
   ---------------------------- "B-IfFalse"
   (valof ρ (if e_1 e_2 e_3) v)])


























