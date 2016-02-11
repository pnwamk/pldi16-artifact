#lang racket

(require redex
         "base-lang.rkt"
         "base-helpers.rkt"
         "subtype.rkt"
         "subtype-helpers.rkt"
         "well-typed.rkt"
         redex-chk)


(define-judgment-form RTR-Base
  #:mode (exists-rho-sat-arg O I)
  #:contract (exists-rho-sat-arg ρ any)

  [(where ρ #f)
   ----------------
   (exists-rho-sat-arg ρ any)])


(define-metafunction RTR-Base
  rho-union : ρ ρ -> ρ
  [(rho-union ([x v_x] ...) ([y v_y] ...))
   ([x v_x] ... [y v_y] ...)])

(define-judgment-form RTR-Base
  #:mode (exists-no-value-st O I)
  #:contract (exists-no-value-st v any)
  [(where v #f)
   ---------------------
   (exists-no-value-st v any)])

(define-judgment-form RTR-Base
  #:mode (sat I I)
  #:contract (sat ρ P)

  [(exists-sat-env ρ Δ)
   (wt-T Δ (rho-lookup ρ o) T)
   ---------------- "M-Type"
   (sat ρ (@ o T))]

  [(wt-T mt-Δ (rho-lookup ρ o) S)
   (exists-no-value-st v "∃Δ. ρ ⊨ Δ and Δ ⊢ v : S and Δ ⊢ v : T")
   ---------------- "M-NotType"
   (sat ρ (¬ (@ o T)))]

  [(sat ρ TT) "M-Top"]

  [(sat ρ P_i) ...
   ---------------- "M-And"
   (sat ρ (And P_i ...))]

  [(sat ρ P_i)
   ---------------- "M-Or"
   (sat ρ (Or P_0 ... P_i P_i+1 ...))]

  [(exists-rho-sat-arg ρ_e (And (@ x T) ...))
   (sat (rho-union ρ ρ_e) P)
   ---------------- "M-Exists"
   (sat ρ (∃ ([x : T] ...) P))]

  [(where (rho-lookup ρ x) (rho-lookup ρ o))
   ---------------- "M-Alias"
   (sat ρ (↦ x o))])