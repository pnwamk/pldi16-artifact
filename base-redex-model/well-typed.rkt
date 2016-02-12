#lang racket

(require redex
         "base-lang.rkt"
         "base-helpers.rkt"
         "subtype.rkt"
         "select-type.rkt"
         "redex-chk.rkt")

(provide val-type
         wt
         wt-T
         exists-sat-env)

;; ----------------------------------------------------------
;; Types of primitives  int? bool? pair? not + - * <=
(define-metafunction RTR-Base
  val-type : v -> Res or #f
  [(val-type n) (Result Int TT FF)]
  [(val-type true) (Result True TT FF)]
  [(val-type false) (Result False FF TT)]
  [(val-type int?)
   (Result (Fun ([x : Any]) -> (Result Bool (@ x Int) (¬ (@ x Int)))) TT TT)]
  [(val-type bool?)
   (Result (Fun ([x : Any]) -> (Result Bool (@ x Bool) (¬ (@ x Bool)))) TT TT)]
  [(val-type pair?)
   (Result (Fun ([x : Any]) -> (Result Bool (@ x (Pair Any Any)) (¬ (@ x (Pair Any Any))))) TT TT)]
  [(val-type not)
   (Result (Fun ([x : Any]) -> (Result Bool (@ x False) (¬ (@ x False)))) TT TT)]
  [(val-type +)
   (Result (Fun ([x : Int] [y : Int]) -> (Result Int TT FF)) TT FF)]
  [(val-type -)
   (Result (Fun ([x : Int] [y : Int]) -> (Result Int TT FF)) TT FF)]
  [(val-type *)
   (Result (Fun ([x : Int] [y : Int]) -> (Result Int TT FF)) TT FF)]
  [(val-type <=)
   (Result (Fun ([x : Int] [y : Int]) -> (Result Bool TT TT)) TT FF)]
  ;; we use specific typing judgments for the others
  [(val-type v) #f])

;; ----------------------------------------------------------
;; Well-Typed judgement (simplified -- type only, ignores propositions)
(define-judgment-form RTR-Base
  #:mode (wt-T I I O)
  #:contract (wt-T Δ_ e_ T_)
  #:inv (wf Δ_ e_ )
  
  [(wt Δ e (Result T P Q))
   ----------------
   (wt-T Δ e T)])

;; ----------------------------------------------------------
;; Well-Typed judgement
(define-judgment-form RTR-Base
  #:mode (wt I I O)
  #:contract (wt Δ_ e_ Res_)
  #:inv (wf Δ_ Res_)

  ;; T-Val
  [(where/hidden Res (val-type v))
   ---------------- "T-Val"
   (wt Δ v (val-type v))]

  ;; T-Var
  [(where T (select-type Δ x)) (proves Δ (@ x T))
   ---------------- "T-Var"
   (wt Δ x (Result T (¬ (@ x False)) (@ x False)))]

  ;; T-Lambda
  [(wt (Env (ext Γ [x : T] ...) Ψ) e Res)
   --------------------------------------------- "T-Abs"
   (wt (Env Γ Ψ) (λ ([x : T] ...) e) (Result (Fun ([x : T] ...) -> Res) TT FF))]

  ;; T-App
  [(wt-T Δ e_0 (Fun ([x : T] ..._n) -> Res))
   (wt-T Δ e_1 S) ...
   (subtype Δ S T) ...
   --------------------------------------------- "T-App"
   (wt Δ (e_0 e_1 ..._n) (∃: ([x : S] ...) Res))]

  ;; T-If
  [(wt Δ e_1 (Result T_1 P_1+ P_1-))
   (wt (ext Δ P_1+) e_2 (Result T_2 P_2+ P_2-))
   (wt (ext Δ P_1-) e_3 (Result T_3 P_3+ P_3-))
   (where P_+ (Or: (And: P_1+ P_2+) (And: P_1- P_3+)))
   (where P_- (Or: (And: P_1+ P_2-) (And: P_1- P_3-)))
   --------------------------------------------------- "T-If"
   (wt Δ (if e_1 e_2 e_3) (Result (U* T_2 T_3) P_+ P_-))]


  ;; T-Let
  [(wt Δ e_x (Result T_x P_x+ P_x-))
   (where P_x (Or: (And (¬ (@ x False)) P_x+)
                   (And (@ x False) P_x-)))
   (wt (ext Δ [x : T_x] P_x) e (Result T P_+ P_-))
   -------------------------------------------------- "T-Let"
   (wt Δ (let ([x e_x]) e) (∃: ([x : T_x])
                               (Refine* ([,(gensym) : T]) P_x)
                               P_+
                               P_-))]

  ;; T-Pair
  [(wt-T Δ e_1 T_1) (wt-T Δ e_2 T_2)
   ------------------ "T-Pair"
   (wt Δ (pair e_1 e_2) (Result (Pair* T_1 T_2) TT FF))]

  
  ;; T-First
  [(where/hidden x ,(variable-not-in (term Δ) 'fresh))
   (where/hidden y ,(variable-not-in (term (Δ x)) 'fresh))
   (wt-T Δ e_p T_p) (subtype Δ T_p (Pair Any Any))
   (where T (first-of T_p)) (where P (@ (first x) False))
   (where Res (Result (Refine* ([y : T]) (↦ y (first x))) P (¬ P)))
   ---------------- "T-First"
   (wt Δ (fst e_p) (∃: ([x : T_p]) Res))]

  ;; T-Second
  [(where/hidden x ,(variable-not-in (term Δ) 'fresh))
   (where/hidden y ,(variable-not-in (term (Δ x)) 'fresh))
   (wt-T Δ e_p T_p) (subtype Δ T_p (Pair Any Any))
   (where T (second-of T_p)) (where P (@ (second x) False))
   (where Res (Result (Refine* ([y : T]) (↦ y (second x))) P (¬ P)))
   ---------------- "T-Second"
   (wt Δ (snd e_p) (∃: ([x : T_p]) Res))]

  ;; T-Clos
  [(where/hidden #f #t)
   (exists-sat-env ρ Δ_c) (wt Δ_c (λ ([x : T] ...) e) Res)
   ---------------- "T-Clos"
   (wt Δ (closure ρ ([x : T] ...) e) Res)])

(define-judgment-form RTR-Base
  #:mode (wt<: I I I)
  #:contract (wt<: Δ e T)
  [(wt Δ e (Result S P Q))
   (subtype Δ S T)
   ---------------
   (wt<: Δ e T)])

;; for proof
(define-judgment-form RTR-Base
  #:mode (exists-sat-env I O)
  #:contract (exists-sat-env ρ Δ)
  [(where Δ mt-Δ)
   ---------------------
   (exists-sat-env ρ Δ)])


;; **********************************************************
;; Well-Typed (wt) tests
(module+ test
  (redex-relation-chk
   wt<:
   
   ;; T-Val tests
   [mt-Δ 42 Int]
   [mt-Δ true True]
   [mt-Δ false False]
   [mt-Δ + (Fun ([x : Int] [y : Int]) -> (Result Int TT FF))]
   [#:f mt-Δ 42 (U)]
   
   ;; T-Var
   [(Env {[x : Int]} {}) x Int]
   [(Env {[x : Any]} {(@ x (Pair Any Any))
                      (Or (@ x Int)
                          (@ (first x) Int))})
    x
    (Pair Int Any)]
   [#:f mt-Δ x Any]
   [#:f (Env {[x : Int]} {}) x (U)]
   [#:f (Env {[x : Any]} {(@ x (Pair Any Any))
                          (Or (@ x Int)
                              (@ (first x) Int))})
        x
        (U)]
   
   ;; T-Lambda
   [mt-Δ (λ ([x : Int]) x) (Fun ([y : Int]) -> (Result Int TT FF))]
   [mt-Δ (λ ([x : Int] [y : Int]) 42)
         (Fun ([y : Int] [x : Int]) -> (Result Int TT FF))]
   [#:f mt-Δ (λ ([x : Int]) y) Any]
   [#:f mt-Δ (λ ([x : Int]) x) (U)]
   
   ;; T-App
   [(Env {[b : Bool]} {})
    (not b)
    Bool]
   [mt-Δ ((λ () 42)) Int]
   [mt-Δ (+ 1 2) Int]
   [(Env {[x : Int]} {}) (+ x 2) Int]
   [(Env ((x : Int)) ((Or (And (¬ (@ x False)) TT) (And (@ x False) FF))))
    x
    Int]
   [mt-Δ ((λ ([x : Int]) x) 42) Int]
   [(Env {[x : Int]} {}) ((λ ([x : Int] [y : Int]) (+ x y)) 42 x) Int]
   [(Env {[f : (Fun ([x : Int]) -> (Result Int TT FF))]} {})
    (f 42) Int]
   [#:f mt-Δ (+ 1 false) Any]
   [#:f mt-Δ (+ false 1) Any]
   [#:f mt-Δ ((λ ([x : Int]) x) true) Any]
   [#:f mt-Δ ((λ ([x : Int] [y : Bool]) (+ x y)) 42 false) Any]
   [#:f mt-Δ ((λ ([x : Int]) x)) Any]
   [#:f mt-Δ ((λ ([x : Int]) x) 42 42) Any]
   
   ;; T-If
   [(Env {[f : (Fun () -> (Result Bool TT TT))]} {})
    (if (f) 42 -1)
    Int]
   [(Env {[f : (Fun () -> (Result Bool TT TT))]} {})
    (if (f) 42 false)
    (U Int False)]
   [(Env {[f : (Fun () -> (Result Bool TT TT))]} {})
    (if (f) true false)
    Bool]
   [(Env {[x : Any]} {})
    (if (int? x) x -1)
    Int]
   [(Env {[x : (U Int Bool)]} {})
    (if (int? x) true x)
    Bool]
   [#:f mt-Δ (if (+ 42 true) 42 42) Any]
   [#:f mt-Δ (if 42 (+ 42 true) 42) Any]
   [#:f mt-Δ (if 42 42 (+ 42 true)) Any]
   [#:f (Env {[f : (Fun () -> (Result Bool TT TT))]} {})
        (if (f) 42 false)
        (U)]
   
   ;; T-Let
   [mt-Δ (let ([x 42]) (+ x 0)) Int]
   [(Env {[x : Any]} {})
    (let ([temp (int? x)]) (if temp x -1))
    Int]
   [(Env {[x : Any]} {})
    (let ([temp (int? x)])
      (let ([y x])
        (if temp y -1)))
    Int]
   [(Env {[x : Any] [y : Any]} {})
    (let ([temp1 (int? x)])
      (let ([temp2 (if temp1 (int? y) false)])
        (if temp2 (+ x y) 42)))
    Int]
   [mt-Δ
    (let ([f (λ ([x : Int] [y : Int]) (+ x y))])
      (f 42 0))
    Int]
   [#:f mt-Δ (let ([x true]) (+ x 0)) Any]
   [#:f (Env {[x : Any]} {})
        (let ([temp (int? x)])
          (let ([y x])
            (if temp y -1)))
        (U)]
   
   ;; T-Pair
   [mt-Δ
    (pair 42 42)
    (Pair Int Int)]
   [(Env {[x : Bool]} {})
    (pair (not x) (+ 1 41))
    (Pair Bool Int)]
   [(Env {[x : Int] [y : Bool]} {})
    (pair x y)
    (Pair Int Bool)]
   [#:f mt-Δ
        (pair 42 42)
        (U)]
   [#:f (Env {[x : Int] [y : Bool]} {})
        (pair x y)
        (U)]
   
   ;; T-First
   [(Env {[p : (Pair Int Bool)]} {})
    (fst p)
    Int]
   [(Env {[p : (Pair Any Int)]} {})
    (if (int? (fst p))
        p
        (pair 42 42))
    (Pair Int Int)]
   [(Env {[p : (Pair Any Any)]} {})
    (let ([temp (int? (fst p))])
      (let ([y (fst p)])
        (if temp y -1)))
    Int]
   [(Env {[p : Any]} {})
    (let ([temp1 (pair? p)])
      (let ([temp2 (if temp1 (int? (fst p)) false)])
        (if temp2 (fst p) -1)))
    Int]
   [#:f (Env {[p : Any]} {})
        (fst p)
        Any]
   [(Env {[x : Int]} {})
    (let ([p (pair x 42)])
      (if (int? x) (fst p) -1))
    Int]
   
   ;; T-Second
   [(Env {[p : (Pair Int Bool)]} {})
    (snd p)
    Bool]
   [(Env {[p : (Pair Int Any)]} {})
    (if (int? (snd p))
        p
        (pair 42 42))
    (Pair Int Int)]
   [(Env {[p : (Pair Any Any)]} {})
    (let ([temp (int? (snd p))])
      (let ([y (snd p)])
        (if temp y -1)))
    Int]
   [(Env {[p : Any]} {})
    (let ([temp1 (pair? p)])
      (let ([temp2 (if temp1 (int? (snd p)) false)])
        (if temp2 (snd p) -1)))
    Int]
   [#:f (Env {[p : Any]} {})
        (snd p)
        Any]))

(module+ test
  (display "well-typed.rkt tests complete!"))