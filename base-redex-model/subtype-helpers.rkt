#lang racket

(require redex
         "redex-chk.rkt"
         "base-lang.rkt"
         "base-helpers.rkt")

(provide overlap
         no-overlap
         perm
         simple-env
         renv
         <>)

;; ---------------------------------------------------------
;; overlap
;; whether or not two types potentially overlap
(define-judgment-form RTR-Base
  #:mode (overlap I I)
  #:contract (overlap S T)
  [---------------------- "O-Refl"
   (overlap T T)]
  [---------------------- "O-TopRhs"
   (overlap T Any)]
  [---------------------- "O-TopLhs"
   (overlap Any T)]
  [---------------------- "O-Abs"
   (overlap (Fun ([x_1 : T_1] ..._n) -> Res_1)
            (Fun ([x_2 : T_2] ..._n) -> Res_2))]
  [(overlap S_i T)
   ---------------------- "O-UnionL"
   (overlap (U S_0 ... S_i S_i+1 ...) T)]
  [(overlap S T_i)
   ---------------------- "O-UnionR"
   (overlap S (U T_0 ... T_i T_i+1 ...))]
  [(overlap S T)
   ---------------------- "O-RefineL"
   (overlap (Refine ([x : S]) P) T)]
  [(overlap S T)
   ---------------------- "O-RefineR"
   (overlap T (Refine ([x : S]) P))]
  [(overlap S T)
   ---------------------- "O-ExistsL"
   (overlap (∃ ([x : S_x] ...) S) T)]
  [(overlap T S)
   ---------------------- "O-ExistsR"
   (overlap T (∃ ([x : S_x] ...) S))]
  [(overlap S_1 T_2)
   (overlap S_2 T_2)
   ---------------------- "O-Pair"
   (overlap (Pair T_1 T_2) (Pair S_1 S_2))])

(define-judgment-form RTR-Base
  #:mode (no-overlap I I)
  #:contract (no-overlap T S)
  [(where #f (overlap T S))
   -------------------------
   (no-overlap T S)])

;; ---------------------------------------------------------
;; overlap tests
(module+ test
  (redex-relation-chk
   overlap
   [Int Int]
   [Int Any]
   [Any Int]
   [#:f Int True]
   [Int (U Int True)]
   [(U Int True) Int]
   [#:f Bool Int]
   [#:f Int Bool]
   [Int (Refine ([i : Int]) TT)]
   [(Refine ([i : Int]) TT) Int]
   [#:f (Refine ([i : Int]) TT) Bool]
   [#:f Bool (Refine ([i : Int]) TT)]
   [(Fun ([x : Bool]) -> (Result Bool TT FF))
    (Fun ([x : Int]) -> (Result Bool TT FF))]
   [#:f (Fun ([x : Bool]) -> (Result Bool TT FF))
        (Fun () -> (Result Bool TT FF))]))


;; ---------------------------------------------------------
;; simple-env
;; and env where all that is left is (¬ (OfType))
;; and X and (¬ X)
(define-metafunction RTR-Base
  simple-env : any -> boolean
  [(simple-env (Env any any_props))
   (simple-env any_props)]
  [(simple-env any_props)
   ,(andmap (disjoin Not? X?) (term any_props))])


;; true for [x : ⊥], [x : Refine} or [x : Exists]
(define (special-type-entry? te)
  (match te
    [(list (? symbol?) ': (or (? Bot?)
                              (? Refine?)
                              (? Exists?)))
     #t]
    [else #f]))

;; permute
;; this function helps us sort the proposition and type
;; environments since they are 'sets' but implemented
;; with lists and we'd like to not explore
;; every possible list permutation during our
;; proof search
(define (permute env)
  (match-define (list 'Env t-env p-env) env)
  (match* (t-env p-env)
    ;; Γ Elim Rule! #f
    [((cons (list (? symbol?) ': (or (? Bot?)
                                     (? Refine?)
                                     (? Exists?)))
            rst)
      (cons 'TT other-rst))
     #f]
    ;; Bring Γ elims to head
    [(t-env _)
     #:when (ormap special-type-entry? t-env)
     (define-values (specials norms) (partition special-type-entry? t-env))
     `(Env ,(append specials norms)
           ,(cond
              [(or (empty? p-env)
                   (not (TT? (car p-env))))
               (cons (term TT) p-env)]
              [else p-env]))]
    ;; skip TT
    [(_ _)
     #:when (ormap TT? p-env)
     (define others (filter-not TT? p-env))
     (term (Env ,t-env ,others))]
    ;; Skip (↦ x x)
    [(_ `((↦ ,x ,x) . ,rst))
     `(Env ,t-env ,rst)]
    ;; Elim rules for Ψ only
    [(_ (cons (or (? FF?)
                  (? OfType?)
                  (? And?)
                  (? Exists?))
              _))
     #f]
    ;; bring Ψ elim to head
    ;; bring FF, OfType, And, Alias, and Exists to head
    [(_ _ )
     #:when (ormap (disjoin FF? OfType? And? Exists?) p-env)
     (define-values (front back)
       (partition  (disjoin FF? OfType? And? Exists?) p-env))
     `(Env ,t-env ,(append front back))]
    ;; alias elim rule
    [(`([,x : ,T]  . ,rst1) `((↦ ,x ,o) . ,rst2))
     #f]
    ;; bring alias to head
    ;; bring type for Alias to the head
    [(_ `((↦ ,x ,o) . ,rst2))
     (define-values (xs others)
       (partition (λ (y:t) (equal? (car y:t) x)) t-env))
     (unless (not (empty? xs)) (error 'permutation "no matching typeof!"))
     `(Env ,(append xs others) ,p-env)]
    [(_ _)
     #:when (ormap Alias? p-env)
     (define-values (front back)
       (partition Alias? p-env))
     `(Env ,t-env ,(append front back))]
    ;; Okay, now we can eliminate Ors
    [(_ (cons (? Or?) rst))
     #f]
    ;; bring Or to the front for elimination
    [(_ _)
     #:when (ormap Or? p-env)
     (define-values (ors not-ors) (partition Or? p-env))
     `(Env ,t-env ,(append ors not-ors))]
    ;; ----------------------------------------------------------------------
    ;; All that is left at this point is things of the form
    ;; (¬ A) and X -- we just need to make sure the (¬ (OfType))
    ;; propositions get to the front first
    ;; ----------------------------------------------------------------------
    ;; (not oftype) at head, we're good
    [(_ (cons (? NotOfType?) rst))
     #f]
    ;; bring not oftypes to head
    [(_ _)
     #:when (ormap NotOfType? p-env)
     (define-values (not-types others) (partition NotOfType? p-env))
     `(Env ,t-env ,(append not-types others))]
    ;; all that's left is X and (Not X), no permutation
    [(l r) #f]))

(define-metafunction RTR-Base
  perm : Δ -> Δ or #f
  [(perm Δ) ,(permute (term Δ))])


(define-metafunction RTR-Base
  renv : ([x : T] ...) (P ...) -> Δ
  [(renv ([x : T] ...) (P ...))
   (Env {[x_3 : (Pair Any (U (Pair Int Int) Int))]
         [x_2 : (Pair Any Any)]
         [x_1 : Any]
         [x : T] ...}
        ,(shuffle (list* (term TT)
                         (term (Or THEORY-SPECIFIC-FORMULA (@ x_1 Any)))
                         (term (And (@ x_1 Int)
                                    (@ (first x_2) Any)))
                         (term (¬ (@ (second x_3) Int)))
                         (term (∃ ([x_4 : Any]) (@ x_4 Int)))
                         (term (P ...)))))
   (where x_4 ,(gensym))
   (where x_3 ,(gensym))
   (where x_2 ,(gensym))
   (where x_1 ,(gensym))])

(define-judgment-form RTR-Base
  #:mode (<> I I)
  #:contract (<> any any)
  [---------------------
   (<> any_!_1 any_!_1)])