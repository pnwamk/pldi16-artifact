#lang racket

(require redex
         "base-lang.rkt"
         "base-helpers.rkt"
         "subtype.rkt"
         "subtype-helpers.rkt"
         redex-chk)

(provide select-type)

(define (ysym) 'y)

(define-metafunction RTR-Base
  select-type : Δ x -> T or #f
  [(select-type (Env Γ Ψ) x)
   ,(if (Fun? (term T_*))
        (term T_*)
        (term (Refine* ([y : T_*]) (↦ y x))))
   (where (Γ_* (P ...)) (simplify-Γ Γ))
   (where ([Ψ_+ Ψ_- o] ...) (->dnf (ext Ψ P ...) ((()() x))))
   (where (T ...)
          ,(let ([ts (for/list ([ps+ (in-list (term (Ψ_+ ...)))]
                                [ps- (in-list (term (Ψ_- ...)))]
                                [obj (in-list (term (o ...)))])
                       (term (choose-type Γ_* ,ps+ ,ps- ,obj)))])
             (cond
               [(empty? ts) (term ((lookup Γ x)))]
               [else ts])))
   #;(where any ,(printf "select-type ~a ~a \n  Γ*: ~a \n  Ψ*: ~a\n DNF: ~a\n\n ---> ~a\n\n"
                       (term (Env Γ Ψ))
                       (term x)
                       (term Γ_*)
                       (term (ext Ψ P ...))
                       (term ([Ψ_+ Ψ_-] ...))
                       (term (T ...))))
   (where y ,(variable-not-in (term x) (ysym)))
   (where T_* (U* T ...))]
  [(select-type (Env Γ Ψ) x) #f])

(define-metafunction RTR-Base
  simplify-Γ : Γ -> (Γ (P ...))
  [(simplify-Γ Γ_1)
   (Γ_2 (P ...))
   (where ((P ...) Γ_2)
          ,(call-with-values (λ () (partition P? (term (raw-simplify-Γ Γ_1))))
                             list))])

(define-metafunction RTR-Base
  raw-simplify-Γ : (any ...) -> (any ...)
  [(raw-simplify-Γ {}) {}]
  [(raw-simplify-Γ {[x : (Refine ([y : T]) P)] any ...})
   (raw-simplify-Γ {[x : T] (subst P ([x / y])) any ...})]
  [(raw-simplify-Γ {[x : (∃ ([y : T] ...) S)] any ...})
   (raw-simplify-Γ {[x : S] [y : T] ... any ...})]
  [(raw-simplify-Γ {[x : T] any ...})
   ([x : T] any_rec ...)
   (where (any_rec ...) (raw-simplify-Γ {any ...}))]
  [(raw-simplify-Γ {P any ...})
   (P any_rec ...)
   (where (any_rec ...) (raw-simplify-Γ {any ...}))])

;; ---------------------------------------------------------
;; takes a Ψ and converts it to DNF (more or less),
;; where each 'disjunct' is a pair of Ψ, where the
;; lhs is all positive A props and the rhs is
;; the negative (¬ A) props
(define-metafunction RTR-Base
  ->dnf : Ψ ([Ψ Ψ o] ...)
  -> ([Ψ Ψ o] ...)
  [(->dnf () ([Ψ_+ Ψ_- o] ...)) ([Ψ_+ Ψ_- o] ...)]
  [(->dnf (TT any ...) ([Ψ_+ Ψ_- o] ...))
   (->dnf (any ...) ([Ψ_+ Ψ_- o] ...))]
  [(->dnf (FF any ...) ([Ψ_+ Ψ_- o] ...))
   ()]
  [(->dnf ((@ o_1 (Refine ([x : T]) P)) any ...) ([Ψ_+ Ψ_- o] ...))
   (->dnf ((@ o_1 T) (subst P ([o_1 / x])) any ...) ([Ψ_+ Ψ_- o] ...))]
  [(->dnf ((@ o_1 (∃ ([x : T] ...) S)) Q ...) ([Ψ_+ Ψ_- o] ...))
   (->dnf ((@ x T) ... (@ o_1 S) Q ...) ([Ψ_+ Ψ_- o] ...))] 
  [(->dnf (A any ...) ([Ψ_+ Ψ_- o] ...))
   (->dnf (any ...) ([(ext Ψ_+ A) Ψ_- o] ...))]
  [(->dnf ((¬ A) any ...) ([Ψ_+ Ψ_- o] ...))
   (->dnf (any ...) ([Ψ_+ (ext Ψ_- (¬ A)) o] ...))]
  [(->dnf ((And P ...) any ...) ([Ψ_+ Ψ_- o] ...))
   (->dnf (P ... any ...) ([Ψ_+ Ψ_- o] ...))]
  [(->dnf ((↦ x o_x) any ...) ([Ψ_+ Ψ_- o] ...))
   (->dnf (subst (any ...) ([o_x / x])) (subst ([Ψ_+ Ψ_- o] ...) ([o_x / x])))]
  [(->dnf ((∃ ([x : T] ...) P) any ...) ([Ψ_+ Ψ_- o] ...))
   (->dnf ((@ x T) ... P any ...) ([Ψ_+ Ψ_- o] ...))]
  [(->dnf ((Or P ...) any ...) ([Ψ_1+ Ψ_1- o_1] ...))
   ([Ψ_2+ Ψ_2- o_2] ... ...)
   (where (([Ψ_2+ Ψ_2- o_2] ...) ...)
          ((->dnf (P any ...) ([Ψ_1+ Ψ_1- o_1] ...)) ...))])

(define-metafunction RTR-Base
  choose-type : Γ Ψ_+ Ψ_- o -> T or #f
  [(choose-type {any_l ... [y : (U)] any_r ...} {} {} o)
   (U)]
  [(choose-type Γ {} {} o) (lookup Γ o)]
  [(choose-type Γ {(@ o_T T) any ...} Ψ_- o)
   (choose-type (update-Γ Γ pos o_T T) {any ...} Ψ_- o)]
  [(choose-type Γ {A any ...} Ψ_- o)
   (choose-type Γ {any ...} Ψ_- o)]
  [(choose-type Γ {} {(¬ (@ o_T T)) any ...} o)
   (choose-type (update-Γ Γ neg o_T T) {} {any ...} o)]
  [(choose-type Γ {} {(¬ A) any ...} o)
   (choose-type Γ {} {any ...} o)])



(module+ test
  (redex-chk
   [#:= (select-type (Env ((x : Any)) ((And (@ x Any) (@ x Int)))) x)
        (Refine ((y : Int)) (↦ y x))]))


