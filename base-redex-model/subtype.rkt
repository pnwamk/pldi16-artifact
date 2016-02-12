#lang racket

(require redex
         "base-lang.rkt"
         "base-helpers.rkt"
         "subtype-helpers.rkt"
         "redex-chk.rkt")

(provide subtype
         proves PROVES
         update
         restrict
         remove
         update-env
         update-Γ)

;; ---------------------------------------------------------
;; subtype
(define-judgment-form RTR-Base
  #:mode (subtype I I I)
  #:contract (subtype Δ_ any_l any_r)
  #:inv (wf Δ_ (any_l any_r))
  
  [(subtype Δ T T) "S-Refl"]

  [(subtype Δ T Any) "S-Top"]

  [(subtype Δ S_i T) ...
   --------------------- "S-UnionSub"
   (subtype Δ (U S_i ...) T)]
  
  [(subtype Δ S T_i)
   --------------------- "S-UnionSuper"
   (subtype Δ S (U T_0 ... T_i T_i+1 ...))]
  
  [(subtype Δ S T)
   --------------------- "S-RefineWeaken"
   (subtype Δ (Refine ([x : S]) P) T)]

  [(proves (ext Δ [x : S] P) (@ x T))
   --------------------- "S-RefineSub"
   (subtype Δ (Refine ([x : S]) P) T)]

  [(subtype Δ S T) (proves (ext Δ [x : S]) P)
   --------------------- "S-RefineSuper"
   (subtype Δ S (Refine ([x : T]) P))]

  [(subtype Δ T_2i T_1i) ...
   (subtype (ext Δ [x_i : T_2i] ...) Res_1 (subst Res_2 ([x_i / y_i] ...)))
   --------------------- "S-Fun"
   (subtype Δ (Fun ([x_i : T_1i] ..._n) -> Res_1) (Fun ([y_i : T_2i] ..._n) -> Res_2))]

  [(subtype Δ T_1 T_2) (subtype Δ S_1 S_2)
   ------------------- "S-Pair"
   (subtype Δ (Pair T_1 S_1) (Pair T_2 S_2))]

  [(subtype (ext Δ [x : T_x] ...) T S)
   ------------------- "S-ExistsSub"
   (subtype Δ (∃ ([x : T_x] ...) T) S)]

  [(subtype Δ S T)
   (proves (ext Δ P_+) Q_+) (proves (ext Δ P_-) Q_-)
   ------------------- "SR-Result"
   (subtype Δ (Result S P_+ P_-) (Result T Q_+ Q_-))])


;; *********************************************************
;; subtype tests
(module+ test
  (redex-relation-chk
   subtype
   [mt-Δ Int Int]
   [mt-Δ Int Any]
   [#:f mt-Δ Any Int]
   [mt-Δ Int (U Int Bool)]
   [#:f mt-Δ (U Int Bool) Int]
   [mt-Δ (Pair Int Int) (Pair Int Any)]
   [#:f mt-Δ (Pair Int Any) (Pair Int Int)]
   [mt-Δ (Fun () -> (Result True TT FF))
         (Fun () -> (Result Bool TT TT))]
   [#:f mt-Δ
        (Fun () -> (Result Bool TT TT))
        (Fun () -> (Result True TT FF))]
   [#:f mt-Δ
        (Fun () -> (Result True TT FF))
        (Fun ([x : Any]) -> (Result Bool TT TT))]
   [#:f mt-Δ
        (Fun () -> (Result True TT FF))
        (Fun ([x : Any]) -> (Result Bool TT TT))]
   [#:f mt-Δ
        (Fun ([x : Any]) -> (Result True TT FF))
        (Fun () -> (Result Bool TT TT))]
   [mt-Δ
    (Fun ([x : Any]) -> (Result True TT FF))
    (Fun ([x : Bool]) -> (Result Bool TT TT))]
   [(Env {[y : Int]} {})
    (Refine ([x : Int]) (@ y Int))
    Int]
   [mt-Δ
    (Refine ([x : Int]) TT)
    Int]
   [(Env {[x : Any] [y : Any]} {})
    (Refine ([q : Int]) (And (@ x Int) (@ y Bool)))
    (Refine ([q : Int]) (Or (@ x Int) (@ y Bool)))]
  [#:f (Env {[x : Any] [y : Any]} {})
       (Refine ([q : Int]) (Or (@ x Int) (@ y Bool)))
       (Refine ([q : Int]) (And (@ x Int) (@ y Bool)))]
  [mt-Δ
   (∃ ([x : Any]) Int)
   Int]
  [#:f mt-Δ
       (∃ ([x : Any]) Any)
       Int]))

;; proves / PROVES
;; we use two logical proves relations in this model
;; to restrict the order we try applying
;; elimination/introduction rules (otherwise Redex would
;; try all possibilities! yikes!)
(define-judgment-form RTR-Base
  #:mode (proves I I)
  #:contract (proves Δ_ P_)
  #:inv (wf Δ_ P_)
  [(where Δ_* (perm Δ))
   (proves Δ_* P)
   --------------------- "proves-perm"
   (proves Δ P)]

  [(where #f (perm Δ))
   (PROVES Δ P)
   --------------------- "proves"
   (proves Δ P)])

;; ---------------------------------------------------------
;; proves
(define-judgment-form RTR-Base
  #:mode (PROVES I I)
  #:contract (PROVES Δ_ P_)
  #:inv (wf Δ_ P_)

  ;; - - - ELIMINATION RULES - - -

  [--------------------- "L-Refl"
   (PROVES (Env Γ {R Q ...}) R)]
  
  [(where/hidden #t (simple-env (Env Γ Ψ)))
   (subtype (Env Γ Ψ) (lookup Γ o) T)
   --------------------- "L-Subtype"
   (PROVES (Env Γ Ψ) (@ o T))]

  [(where/hidden #t (simple-env (Env Γ {(¬ (@ o S)) P ...})))
   (subtype (Env Γ {P ...}) T S)
   --------------------- "L-SubtypeNot"
   (PROVES (Env Γ {(¬ (@ o S)) P ...}) (¬ (@ o T)))]

  [(where/hidden #t (simple-env (Env Γ Ψ)))
   (no-overlap (lookup Γ o) T)
   --------------------- "L-NoOverlap"
   (PROVES (Env Γ Ψ) (¬ (@ o T)))]

  [(PROVES Δ TT) "L-True"]
  
  [(PROVES (Env Γ {FF P ...}) R) "L-False"]

  [(PROVES (Env {[x : (U)] [y : T] ...} Ψ) R) "L-Bot"]

  [--------------------- "L-Absurd"
   (PROVES (Env Γ {P (¬ P) Q ...}) R)]
  
  [(proves (Env Γ {P ... Q ...}) R)
   --------------------- "L-AndE"
   (PROVES (Env Γ {(And P ...) Q ...}) R)]

  [(where/hidden #t (simple-env Δ))
   (proves Δ R_i) ...
   --------------------- "L-AndI"
   (PROVES Δ (And R_i ...))]
  
  [(proves (Env Γ {P_i Q_0 ...}) R) ...
   --------------------- "L-OrE"
   (PROVES (Env Γ {(Or P_i ...) Q_0 ...}) R)]

  [(where/hidden #t (simple-env Δ))
   (proves Δ R_i)
   --------------------- "L-OrI"
   (PROVES Δ (Or R_0 ... R_i R_i+1 ...))]

  [(where/hidden #t #f)
   (PROVES (Env Γ {(Or (¬ P) ...)  Q ...}) R)
   --------------------- "L-DeM1"
   (PROVES (Env Γ {(¬ (And P ...))  Q ...}) R)]

  [(where/hidden #t #f)
   (PROVES (Env Γ {(And (¬ P) ...)  Q ...}) R)
   --------------------- "L-DeM2"
   (PROVES (Env Γ {(¬ (Or P ...))  Q ...}) R)]

  [(<> x o)
   (proves (subst (Env {[y : S] ...} {(@ o T) P ...}) ([o / x])) (subst R ([o / x])))
   --------------------- "L-AliasE"
   (PROVES (Env {[x : T] [y : S] ...} {(↦ x o) P ...}) R)]

  [(PROVES Δ (↦ x x)) "L-Identity"]

  [(proves (Env {[x : T] [y : S] ...} (ext Ψ (subst P ([x / z])))) R)
   ---------------------------------- "L-RefineE"
   (PROVES (Env {[x : (Refine ([z : T]) P)] [y : S] ...} Ψ) R)]

  [(where/hidden #t (simple-env Δ))
   (proves Δ (@ o T)) (proves Δ (subst R ([o / x])))
   ---------------------------------- "L-RefineI"
   (PROVES Δ (@ o (Refine ([x : T]) R)))]
  
  [(where/hidden #t (simple-env Δ))
   (proves (ext Δ (@ o (Refine ([x : T]) R))) FF)
   ---------------------------------- "L-RefineINot"
   (PROVES Δ (¬ (@ o (Refine ([x : T]) R))))]

  [(proves (Env {[x : T] [z_i : T_i] ... [y : S] ...} Ψ) R)
   ---------------------------------- "L-ExistsType"
   (PROVES (Env {[x : (∃ ([z_i : T_i] ...) T)] [y : S] ...} Ψ) R)]
  
  [(proves (Env (ext Γ [x : T] ...) {P Q ...}) R)
   --------------------- "L-ExistsProp"
   (PROVES (Env Γ {(∃ ([x : T] ...) P) Q ...}) R)]
  
  [(proves (update-env (Env Γ {P ...}) pos o T) R)
   --------------------- "L-Update"
   (PROVES (Env Γ {(@ o T) P ...}) R)]

  [(where/hidden #t (simple-env (Env Γ {(¬ (@ o T)) P ...})))
   (proves (update-env (Env Γ {P ...}) neg o T) R)
   --------------------- "L-UpdateNot"
   (PROVES (Env Γ {(¬ (@ o T)) P ...}) R)]

  [(where/hidden #t (simple-env (Env Γ Ψ)))
   (where TH (theory-of R))
   (provable-in-theory TH Ψ R)
   -------------------------- "L-Theory"
   (PROVES (Env Γ Ψ) R)])

;; ---------------------------------------------------------
;; theory placeholder stuff
(define-metafunction RTR-Base
  theory-of : any -> any
  [(theory-of any) BASE-THEORY])

(define-judgment-form RTR-Base
  #:mode (provable-in-theory I I I)
  #:contract (provable-in-theory any any any)
  [-------------------------------- "Th-Atom"
   (provable-in-theory any {any_l ... P any_r ...} P)])

;; *********************************************************
;; subtype tests that rely on proves
(module+ test
  (redex-relation-chk
   subtype
   [mt-Δ Int Any]
   [#:f mt-Δ Any Int]
   [mt-Δ
    (Fun ([x : Any]) -> (pred (@ x Int)))
    (Fun ([y : Any]) -> (pred (@ y Int)))]
   [#:f mt-Δ
        (Fun ([x : Any]) -> (pred (@ x Int)))
        (Fun ([y : Any]) -> (pred (@ y (U Int Bool))))]
   [#:f mt-Δ
        (Fun ([x : Any]) -> (pred (@ x Int)))
        (Fun ([y : Any]) -> (pred (@ y (U Int Bool))))]
   [(Env ([y : Int]) ())
    (Refine ([x : Any]) (@ y Int))
    (Refine ([x : Any]) (@ y Any))]
   [#:f (Env ([y : Any]) ())
        (Refine ([x : Any]) (@ y Any))
        (Refine ([x : Any]) (@ y Int))]
   [(Env ((x : Int)) ((Or (And (¬ (@ x False)) TT) (And (@ x False) FF))))
    (Refine ((y : Int)) (↦ y x))
    Int]))

;; ---------------------------------------------------------
;; restrict
(define-metafunction RTR-Base
  restrict : Δ_ T_1 T_2 -> S_
  #:pre (wf Δ_ (T_1 T_2))
  #:post (wf Δ_ S_)
  [(restrict Δ T S) (U)
   (judgment-holds (no-overlap S T))]
  [(restrict Δ (U T ...) S) (U* (restrict Δ T S) ...)]
  [(restrict Δ T S) T
   (judgment-holds (subtype Δ T S))]
  [(restrict Δ T S) S])

;; *********************************************************
;; restrict tests
(module+ test
  (redex-chk
   (restrict mt-Δ Any Int) Int
   (restrict mt-Δ Int Any) Int
   #:= (restrict mt-Δ Int Bool) (U)
   [(restrict mt-Δ (U Bool Int) Int) Int]))

;; ---------------------------------------------------------
;; remove
(define-metafunction RTR-Base
  remove : Δ_ T_1 T_2 -> S_
  #:pre (wf Δ_ (T_1 T_2))
  #:post (wf Δ_ S_)
  [(remove Δ T S) (U)
   (judgment-holds (subtype Δ T S))]
  [(remove Δ (U T ...) S) (U* (remove Δ T S) ...)]
  [(remove Δ T S) T])

;; *********************************************************
;; remove tests
(module+ test
  (redex-chk
   #:= (remove mt-Δ Any Int) Any
   #:= (remove mt-Δ Int Any) (U)
   #:= (remove mt-Δ Int Bool) Int
   #:= (remove mt-Δ (U Bool Int) Int) Bool))

;; ---------------------------------------------------------
;; update
(define-metafunction RTR-Base
  update : Δ_ T_1 (field ...) ± T_2 -> S_
  #:pre (wf Δ_ (T_1 T_2))
  #:post (wf Δ_ S_)
  [(update Δ T () pos S) (restrict Δ T S)]
  [(update Δ T () neg S) (remove Δ T S)]
  [(update Δ (Pair T_1 T_2) (first field ...) ± S)
   (Pair* (update Δ T_1 (field ...) ± S) T_2)]
  [(update Δ (Pair T_1 T_2) (second field ...) ± S)
   (Pair* T_1 (update Δ T_2 (field ...) ± S))]
  ;; meh, let's not do anything crazy in the last case
  [(update Δ T (field ...) ± S) T])

;; *********************************************************
;; update tests
(module+ test
  (redex-chk
   #:= (update mt-Δ Any () pos Int) Int
   #:= (update mt-Δ Int () pos Any) Int
   #:= (update mt-Δ Int () pos Bool) (U)
   #:= (update mt-Δ (U Bool Int) () pos Int) Int
   #:= (update mt-Δ (Pair (U Bool Int) Any) (first) pos Int) (Pair Int Any)
   #:= (update mt-Δ (Pair Any (U Bool Int)) (second) pos Int) (Pair Any Int)
   #:= (update mt-Δ Any () neg Int) Any
   #:= (update mt-Δ Int () neg Any) (U)
   #:= (update mt-Δ Int () neg Bool) Int
   #:= (update mt-Δ (U Bool Int) () neg Int) Bool
   #:= (update mt-Δ (Pair (U Bool Int) Any) (first) neg Int) (Pair Bool Any)
   #:= (update mt-Δ (Pair Any (U Bool Int)) (second) neg Int) (Pair Any Bool)))

;; ---------------------------------------------------------
;; update-type-env
(define-metafunction RTR-Base
  update-env : Δ ± o T -> Δ
  [(update-env (Env Γ Ψ) ± o T) (Env (ext Γ [x : S]) Ψ)
   (where x (obj-id o))
   (where S (update (Env Γ Ψ) (lookup Γ x) (obj-path o) ± T))])

(define-metafunction RTR-Base
  update-Γ : Γ ± o T -> Γ
  [(update-Γ Γ ± o T)
   {[x : (update (Env Γ ()) S path ± T)] any_l ... any_r ...}
   (where {any_l ... [x : S] any_r ...} Γ)
   (where path (obj-path o))
   (where x (obj-id o))]
  [(update-Γ {any ...} pos x T)
   {[x : T] any ...}])

;; *********************************************************
;; proves tests (basic)
(module+ test
  (redex-relation-chk
   proves
   [(Env {[x : Any] [y : Int] [z : Any]} {})
    (@ y (U Int Bool))]
   ;; L-Subtype+
   [#:f (Env {[x : (U Int Bool)]} {})
        (@ x Int)]
   
   ;; L-Subtype-
   [(Env {[y : Any] [x : Any] [z : Any]}
         {(¬ (@ x (U Int Bool)))})
    (¬ (@ x Int))]
   [#:f (Env {[x : Any]} {(¬ (@ x Int))})
        (¬ (@ x (U Bool Int)))]
   
   ;; L-NoOverlap
   [(Env {[z : Any] [x : Bool] [y : Any]} {})
    (¬ (@ x Int))]
   [#:f (Env {[x : (U Bool Int)]} {})
        (¬ (@ x Int))]
   ;; L-Update+
   [(Env {[x : (U Bool Int)]} {(@ x Int)})
    (@ x Int)]
   ;; L-Update-
   [(Env {[x : (U Bool Int)]} {(¬ (@ x Bool))})
    (@ x Int)]
   
   ;; L-True
   [(Env {[x : (U Bool Int)]} {(¬ (@ x Bool))})
    TT]
   ;; L-False
   [#:f (Env {[x : (U Bool Int)]} {(¬ (@ x Bool))})
        FF]
   [(Env {[x : (U Bool Int)]} {(¬ (@ x Bool)) FF})
    FF]
   ;; L-Bot
   [(Env {[x : (U)]} {})
    FF]
   ;; L-AndE
   [(Env {[x : Any] [y : Any]} {(And (@ x Int) (@ y Bool))})
    (@ x Int)]
   [(Env {[x : Any] [y : Any]} {(And (@ x Int) (@ y Bool))})
    (@ y Bool)]
   ;; L-AndI
   [(Env {[x : Int] [y : Bool]} {})
    (And (@ x Int) (@ y Bool))]
   [#:f (Env {[x : Int] [y : Bool] [z : Any]} {})
        (And (@ x Int) (@ y Bool) (@ z Int))]
   ;; L-OrE
   [(Env {[x : (U Int Bool)]}
         {(Or (@ x Int)
              (¬ (@ x Bool)))})
    (@ x Int)]
   ;; L-OrI
   [(Env {[x : Any] [y : Bool] [z : Any]} {})
    (Or (@ x Int) (@ y Bool) (@ z (U)))]
   ;; L-Alias
   [(Env {[x : Int] [y : Any]} {(↦ y x)})
    (@ y Int)]
   [(Env {[x : Any] [y : Int]} {(↦ y x)})
    (@ x Int)]
   ;; L-Identity
   [(Env {[x : Any]} {})
    (↦ x x)]
   [#:f (Env {[x : Any] [y : Any]} {})
        (↦ x y)]
   ;; L-RefineE
   [(Env {[x : (Refine ([v : Int]) (@ y Int))] [y : Any]} {})
    (And (@ x Int) (@ y Int))]
   ;; L-RefineI+
   [(Env {[x : Int] [y : Bool]} {})
    (@ x (Refine ([v : (U Int Bool)])
                      (Or (And (@ x Bool) (@ y Int))
                          (And (@ x Int) (@ y Bool)))))]
   [#:f (Env {[x : Int] [y : Bool]} {})
        (@ x (Refine ([v : (U Int Bool)])
                          (Or (And (@ x Bool) (@ y Int))
                              FF)))]
   ;; L-RefineI-
   [#:f (Env {[x : Int]} {})
        (¬ (@ x (Refine ([v : Int]) TT)))]
   [(Env {[x : Int]} {})
    (¬ (@ x (Refine ([v : Int]) FF)))]
   [(Env {[x : (∃ ([z : Int]) (U Int Bool))]}
         {(¬ (@ x Bool))})
    (@ x Int)]
   ;; L-ExistsE2
   [(Env {[x : (U Int Bool)]}
         {(∃ ([z : Int]) (Or (@ x Int)
                                  (¬ (@ z Int))))})
    (@ x Int)]))

;; --------------------------------------------------------------
;; proves tests (basic) + some randomization
(module+ test
  (redex-relation-chk
   proves
   [(renv {[x : Any] [y : Int] [z : Any]} {})
    (@ y (U Int Bool))]
   ;; L-Subtype+
   [#:f (renv {[x : (U Int Bool)]} {})
        (@ x Int)]
   
   ;; L-Subtype-
   [(renv {[y : Any] [x : Any] [z : Any]}
          {(¬ (@ x (U Int Bool)))})
    (¬ (@ x Int))]
   [#:f (renv {[x : Any]} {(¬ (@ x Int))})
        (¬ (@ x (U Bool Int)))]
   
   ;; L-NoOverlap
   [(renv {[z : Any] [x : Bool] [y : Any]} {})
    (¬ (@ x Int))]
   [#:f (renv {[x : (U Bool Int)]} {})
        (¬ (@ x Int))]
   ;; L-Update+
   [(renv {[x : (U Bool Int)]} {(@ x Int)})
    (@ x Int)]
   ;; L-Update-
   [(renv {[x : (U Bool Int)]} {(¬ (@ x Bool))})
    (@ x Int)]
   
   ;; L-True
   [(renv {[x : (U Bool Int)]} {(¬ (@ x Bool))})
    TT]
   ;; L-False
   [#:f (renv {[x : (U Bool Int)]} {(¬ (@ x Bool))})
        FF]
   [(renv {[x : (U Bool Int)]} {(¬ (@ x Bool)) FF})
    FF]
   ;; L-Bot
   [(renv {[x : (U)]} {})
    FF]
   ;; L-AndE
   [(renv {[x : Any] [y : Any]} {(And (@ x Int) (@ y Bool))})
    (@ x Int)]
   [(renv {[x : Any] [y : Any]} {(And (@ x Int) (@ y Bool))})
    (@ y Bool)]
   ;; L-AndI
   [(renv {[x : Int] [y : Bool]} {})
    (And (@ x Int) (@ y Bool))]
   [#:f (renv {[x : Int] [y : Bool] [z : Any]} {})
        (And (@ x Int) (@ y Bool) (@ z Int))]
   ;; L-OrE
   [(renv {[x : (U Int Bool)]}
          {(Or (@ x Int)
               (¬ (@ x Bool)))})
    (@ x Int)]
   ;; L-OrI
   [(renv {[x : Any] [y : Bool] [z : Any]} {})
    (Or (@ x Int) (@ y Bool) (@ z (U)))]
   ;; L-Alias
   [(renv {[x : Int] [y : Any]} {(↦ y x)})
    (@ y Int)]
   [(renv {[x : Any] [y : Int]} {(↦ y x)})
    (@ x Int)]
   ;; L-Identity
   [(renv {[x : Any]} {})
    (↦ x x)]
   [#:f (renv {[x : Any] [y : Any]} {})
        (↦ x y)]
   ;; L-RefineE
   [(renv {[x : (Refine ([v : Int]) (@ y Int))] [y : Any]} {})
    (And (@ x Int) (@ y Int))]
   ;; L-RefineI+
   [(renv {[x : Int] [y : Bool]} {})
    (@ x (Refine ([v : (U Int Bool)])
                      (Or (And (@ x Bool) (@ y Int))
                          (And (@ x Int) (@ y Bool)))))]
   [#:f (renv {[x : Int] [y : Bool]} {})
        (@ x (Refine ([v : (U Int Bool)])
                          (Or (And (@ x Bool) (@ y Int))
                              FF)))]
   ;; L-RefineI-
   [#:f (renv {[x : Int]} {})
        (¬ (@ x (Refine ([v : Int]) TT)))]
   [(renv {[x : Int]} {})
    (¬ (@ x (Refine ([v : Int]) FF)))]
   ;; L-ExistsE1
   [(renv {[x : (∃ ([z : Int]) (U Int Bool))]}
         {(¬ (@ x Bool))})
    (@ x Int)]
   ;; L-ExistsE2
   [(renv {[x : (U Int Bool)]}
          {(∃ ([z : Int]) (Or (@ x Int)
                                   (¬ (@ z Int))))})
    (@ x Int)]))

(module+ test
  (display "subtype.rkt tests complete!"))