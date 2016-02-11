#lang racket

(require redex
         redex-chk
         "base-lang.rkt")

(provide (all-defined-out))

(define-metafunction RTR-Base
  pred : P -> Res
  [(pred P) (Result Bool P (¬ P))])

;; ---------------------------------------------------------
;; field-type
;; reports if a field has a particular associated type
;; (e.g. vector-length -> Integer)
(define-metafunction RTR-Base
  field-type : field -> T
  [(field-type field) Any])

;; ---------------------------------------------------------
;; object derived concepts
;; obj-id
(define-metafunction RTR-Base
  obj-id : o -> x
  [(obj-id x) x]
  [(obj-id (field o)) (obj-id o)])
;; obj-path
(define-metafunction RTR-Base
  obj-path : o -> path
  [(obj-path x) ()]
  [(obj-path (field o))
   (field_rst ... field)
   (where (field_rst ...) (obj-path o))])

(module+ test
  (redex-chk
   #:= (obj-id y) y
   #:= (obj-id (first (second x))) x
   #:= (obj-path x) ()
   #:= (obj-path (first (second x))) (second first)))

;; ---------------------------------------------------------
;; simple-subtype
(define-judgment-form RTR-Base
  #:mode (simple-subtype I I)
  #:contract (simple-subtype any_l any_r)
  
  [--------------------- "S-Refl"
   (simple-subtype T T)]

  [--------------------- "S-Top"
   (simple-subtype T Any)]

  [(simple-subtype S T) ...
   --------------------- "S-UnionSub"
   (simple-subtype (U S ...) T)]
  
  [(simple-subtype S T_i)
   --------------------- "S-UnionSuper"
   (simple-subtype S (U T_0 ... T_i T_i+1 ...))]
  
  [(simple-subtype S T)
   --------------------- "S-RefineWeaken"
   (simple-subtype (Refine ([x : S]) P) T)]

  [(simple-subtype  S_1 T_1)
   (simple-subtype  S_2 T_2)
   ------------------- "S-Pair"
   (simple-subtype (Pair S_1 S_2) (Pair T_1 T_2))]
  
  [(simple-subtype T S)
   ------------------- "S-Exists"
   (simple-subtype (∃ ([x : T_x] ...) T) S)])


(define (add-to-union-list t ts)
  (cond
    [(U? t)
     (for/fold ([ts ts])
               ([new-t (in-list (rest t))])
       (add-to-union-list new-t ts))]
    [(for/or ([cur-t (in-list ts)])
       (term (simple-subtype ,t ,cur-t)))
     ts]
    [else
     (define ts* (filter-not (λ (cur-t) (term (simple-subtype ,cur-t ,t))) ts))
     (cons t ts*)]))

;; ---------------------------------------------------------
;; Union smart constructor
(define-metafunction RTR-Base
  U* : T ... -> T
  [(U*) (U)]
  [(U* (U T ...) S ...)
   (U* T ... S ...)]
  [(U* T S ...)
   ,(let ([ts (sort (for/fold ([t (term (T))])
                              ([new-t (in-list (term (S ...)))])
                      (add-to-union-list new-t t))
                    (λ (a b)
                      (<= (equal-hash-code a)
                          (equal-hash-code b))))])
      (cond
        [(= 1 (length ts)) (first ts)]
        [else (cons 'U ts)]))])

(define-term Bool (U* True False))
(define-term mt-Δ (Env () ()))

(module+ test
  (redex-chk
   (U* Int Int) Int
   (U* (U Int Bool) Bool (U Int)) (U* Int Bool)
   (U* (U Int Bool) Bool (U Any)) Any))

;; ---------------------------------------------------------
;; in (i.e. ∈)
(define-metafunction RTR-Base
  in : any (any ...) -> boolean
  [(in any_1 any_2) ,(and (memq (term any_1) (term any_2)) #t)])

(module+ test
  (redex-chk
   #:f (in x ())
   #:t (in x (a b c x y z))
   #:f (in x (a b c y z))))

;; ---------------------------------------------------------
;; update
;; replaces an id's entry in Γ if it has an entry,
;; or adds new entry
(define-metafunction RTR-Base
  set-type : Γ x T  -> Γ
  [(set-type Γ x T)
   ,(cons (term [x : T])
          (filter-not (λ (t) (eq? (car t) (term x)))
                      (term Γ)))])

(module+ test
  (test-equal (term (set-type {} a Int))
              (term {[a : Int]}))
  (test-equal (term (set-type {[a : Int] [b : Any] [c : Any]} b Int))
              (term {[b : Int] [a : Int] [c : Any]}))
  (test-equal (term (set-type {[a : Int] [b : Any] [c : Any]} d Int))
              (term {[d : Int] [a : Int] [b : Any] [c : Any]})))


;; --------------------------------------------------------------
;; type-path-ref
(define-metafunction RTR-Base
  type-path-ref : T path -> T
  [(type-path-ref T ()) T]
  [(type-path-ref (Pair T S) (first field ...))
   (type-path-ref T (field ...))]
  [(type-path-ref (Pair T S) (second field ...))
   (type-path-ref S (field ...))]
  [(type-path-ref T path) Any])

;; --------------------------------------------------------------
;; lookup
;; type of x in Γ
;; (takes an optional default argument for failure)
(define-metafunction RTR-Base
  [(lookup Γ x)
   ,(for/first ([y:t (in-list (term Γ))]
                #:when (eq? (term x) (first y:t)))
      (third y:t))]
  [(lookup Γ o)
   (type-path-ref (lookup Γ (obj-id o)) (obj-path o))]
  [(lookup (Env Γ any) o) (lookup Γ o)]
  [(lookup ρ x)
   [(lookup Γ x)
   ,(for/first ([y-v (in-list (term ρ))]
                #:when (eq? (term x) (first y-v)))
      (second y-v))]])

(define-metafunction RTR-Base
  lookup/rem : Γ x -> (Γ T)
  [(lookup/rem {[x : T_x] ... [y : T_y] [z : T_z] ...} y)
   ({[x : T_x] ... [z : T_z] ...} T_y)])

(module+ test
  (redex-chk
   #:f (lookup {} a)
   #:f (lookup {[a : Int] [b : Bool] [c : Any]} d)
   [#:= (term (lookup {[a : Int] [b : Bool] [c : Any]} b))
        Bool]
   [#:= (lookup {[a : Int] [b : (Pair Int Bool)] [c : Any]} (first b))
        Int]
   [#:= (lookup {[a : Int] [b : (Pair Int Bool)] [c : Any]}
                (second b))
        Bool]
   [#:= (lookup {[a : Int] [b : (Pair Int (Pair Any Bool))] [c : Any]}
                (first (second b)))
        Any]))


(define-metafunction RTR-Base
  And: : P ... -> P
  [(And: P ... FF Q ...) FF]
  [(And: P ... A Q ... (¬ A) R ...) FF]
  [(And: P ... (¬ A) Q ... A R ...) FF]
  [(And: P ... (And Q ...) R ...)
   (And: P ... Q ... R ...)]
  [(And:) TT]
  [(And: P ...) (And P ...)])

(define-metafunction RTR-Base
  Or: : P ... -> P
  [(Or: P ... TT Q ...) TT]
  [(Or: P ... A Q ... (¬ A) R ...) TT]
  [(Or: P ... (¬ A) Q ... A R ...) TT]
  [(Or: P ... FF Q ...) (Or: P ... Q ...)]
  [(Or: P ... (Or Q ...) R ...)
   (Or: P ... Q ... R ...)]
  [(Or:) FF]
  [(Or: P ...) (Or P ...)])


;; ---------------------------------------------------------
;; Fresh variable functions
(define-metafunction RTR-Base
  fresh-var : any x -> x
  [(fresh-var any x) ,(variable-not-in (term any) (term x))])
(define-metafunction RTR-Base
  fresh-vars : any (x ...) -> (x ...)
  [(fresh-vars any (x ...)) ,(variables-not-in (term any) (term (x ...)))])


;; ---------------------------------------------------------
;; ext
;; environment extension
(define-metafunction RTR-Base
  ext : any any ... -> Δ or Γ or Ψ
  [(ext any) any]
  [(ext (Env Γ Ψ) [x : T] any ...)
   (ext (Env (ext Γ [x : T]) Ψ) any ...)]
  [(ext (Env Γ Ψ) P any ...)
   (ext (Env Γ (ext Ψ P)) any ...)]
  [(ext {[x : T] ... [y : T_old] [z : S] ...}
        [y : T_y])
   {[y : T_y] [x : T] ... [z : S] ...}]
  [(ext {[x : T] ...} [y : T_y] any ...)
   (ext {[y : T_y] [x : T] ...} any ...)]
  [(ext Ψ P ...)
   ,(append (term (P ...)) (term Ψ))])

(module+ test
  (redex-chk
   #:= (ext (Env () ())) mt-Δ
   #:= (ext (Env {} {}) TT) (Env {} {TT})
   #:= (ext (Env {} {TT}) (@ x Int)) (Env {} {(@ x Int) TT})
   #:= (ext (Env {} {TT}) [x : Int]) (Env {[x : Int]} {TT})
   #:= (ext (Env {[y : Int] [x : Any] [z : Bool]} {TT})
            [x : Int])
   (Env {[x : Int] [y : Int] [z : Bool]} {TT})))

;; ---------------------------------------------------------
;; Binder-related Functions
;; ---------------------------------------------------------
;; α=
;; alpha equivalence
(define-metafunction RTR-Base
  α= : any any -> boolean
  [(α= any_1 any_2)
   ,(alpha-equivalent? RTR-Base (term any_1) (term any_2))])

(module+ test
  (redex-chk
   #:t (α= x x)
   #:t (α= (λ ([x : Int]) x)
           (λ ([y : Int]) y))
   #:f (α= (λ ([x : Int]) x)
           (λ ([y : Int]) x))))

;; ---------------------------------------------------------
;; subst
;; standard capture-avoiding substitution
(define-metafunction RTR-Base
  subst : any ([any / x] ...) -> any
  [(subst any ()) any]
  [(subst any ([any_x / x] [any_y / y] ...))
   (subst ,(substitute RTR-Base (term any) (term x) (term any_x))
          ([any_y / y] ...))])

(module+ test
  (redex-chk
   #:= (subst x ([42 / x])) 42
   #:= (subst x ([42 / y])) x
   #:t (α= (subst (λ ([x : Int]) y) ([42 / y]))
           (λ ([x : Int]) 42))
   #:t (α= (subst (λ ([x : Int]) x) ([42 / x]))
           (λ ([x : Int]) x))))

;; ---------------------------------------------------------
;; Smart Refine constructor
(define-metafunction RTR-Base
  Refine* : ([x : T]) P -> T
  [(Refine* ([x : (U)]) P) (U)]
  [(Refine* ([x : (Refine [y : S] Q)]) P)
   (Refine* ([z : S]) (And: (subst P ([z / x])) (subst Q ([z / y]))))
   (where z ,(variable-not-in (term ((Refine ([y : S]) Q) P)) 'fresh))]
  [(Refine* ([x : (Fun ([y : T] ...) -> Res)]) P) (Fun ([y : T] ...) -> Res)]
  [(Refine* ([x : T]) P) (Refine ([x : T]) P)])

;; ---------------------------------------------------------
;; Smart Pair constructor
(define-metafunction RTR-Base
  Pair* : T T -> T
  [(Pair* (U) S) (U)]
  [(Pair* T (U)) (U)]
  [(Pair* (Refine [x : T] P)
          (Refine [y : S] Q))
   (Refine* [p : (Pair* T S)] (And: (subst P ([(first p) / x]))
                                    (subst Q ([(second p) / y]))))
   (where p (fresh-var ((Refine [x : T] P) (Refine [y : S] Q)) p))]
  [(Pair* (Refine [x : T] P) S)
   (Refine* [p : (Pair* T S)] (subst P ([(first p) / x])))
   (where p (fresh-var ((Refine [x : T] P) S) p))]
  [(Pair* T (Refine [x : S] P))
   (Refine* [p : (Pair* T S)] (subst P ([(second p) / x])))
   (where p (fresh-var (T (Refine [x : S] P)) p))]
  [(Pair* T S) (Pair T S)])

;; ---------------------------------------------------------
;; free variables
(define-metafunction RTR-Base
  fv : any -> (x ...)
  [(fv x) (x)]
  ;; λ
  [(fv (λ ([x : T] ...) e))
   ,(set-subtract (apply set-union (term (x_e ...)) (term ((x_T ...) ...)))
                  (term (x ...)))
   (where ((x_T ...) ...) ((fv T) ...))
   (where (x_e ...) (fv e))]
  ;; let
  [(fv (let ([x e_x]) e))
   ,(set-union (term (fv e_x)) (set-remove (term (fv e)) (term x)))]
  ;; Fun
  [(fv (Fun ([x : T] ...) -> Res))
   ,(set-subtract (apply set-union (term (x_R ...)) (term ((x_T ...) ...)))
                  (term (x ...)))
   (where ((x_T ...) ...) ((fv T) ...))
   (where (x_R ...) (fv Res))]
  ;; Refine
  [(fv (Refine ([x : T]) P))
   ,(set-union (term (fv T))
               (filter-not (curry equal? (term x)) (term (fv P))))]
  ;; Exists
  [(fv (∃ ([x : T] ...) any))
   ,(set-subtract (apply set-union (term (x_any ...)) (term ((x_T ...) ...)))
                  (term (x ...)))
   (where ((x_T ...) ...) ((fv T) ...))
   (where (x_any ...) (fv any))]
  [(fv (any ...))
   ,(let ([l (term ((x ...) ...))])
      (cond
        [(empty? l) l]
        [else (apply set-union l)]))
   (where ((x ...) ...) ((fv any) ...))]
  [(fv any) ()])

(define-metafunction RTR-Base
  equal-sets : any any -> boolean
  [(equal-sets any_1 any_2) ,(set=? (term any_1) (term any_2))])

(module+ test
  (redex-relation-chk
   equal-sets
   [(fv 42) ()]
   [(fv (x y)) (x y)]
   [(fv (λ ([x : Int] [y : Int]) (f x y))) (f)]
   [(fv (λ ([x : (Refine ([i : Int]) (@ x Int))] [y : Int])
          (f x y)))
    (f x)]
   [(fv (let ([x q]) (if q x z))) (q z)]
   [(fv (let ([x x]) y)) (x y)]
   [(fv (Fun ([x : (Refine ([q : Any]) (And (@ q Any) (@ r Any)))])
             -> (Result Bool (@ x Int) (¬ (@ y Int)))))
    (r y)]
   [(fv (Fun ([x : (Refine ([q : Any]) (And (@ x Any) (@ r Any)))])
                  -> (Result Bool (@ x Int) (¬ (@ y Int)))))
    (x r y)]
   [(fv (Refine ([x : Int]) (And (@ y Int) (@ x Int))))
    (y)]
   [(fv (Refine [x : (Refine ([i : Int]) (@ x Int))] (@ y Int)))
    (y x)]))

;; ---------------------------------------------------------
;; smart exists
(define-metafunction RTR-Base
  [(∃: () any) any]
  [(∃: ([z : (Refine ([y : S]) (↦ y x))]) T)
   (Refine* ([q : (subst T ([x / z]))]) (@ x S))
   (where q ,(variable-not-in (term T) 'q))]
  [(∃: ([z : (Refine ([y : S]) (↦ y x))]) P)
   (And: (@ x S) (subst P ([z x])))]
  [(∃: ([z : (Refine ([y : S]) (↦ y x))]) (Result T P Q))
   (Result (Refine* ([q : (subst T ([x / z]))]) (@ x S))
           (And: (@ x S) (subst P ([x / z])))
           (And: (@ x S) (subst Q ([x / z]))))
   (where q ,(variable-not-in (term T) 'q))]
  [(∃: ([x : T] ...) (Result S P Q))
   (Result (∃ ([x : T] ...) S)
           (∃ ([x : T] ...) P)
           (∃ ([x : T] ...) Q))]
  [(∃: ([x : T] ...) S P Q)
   (∃: ([x : T] ...) (Result S P Q))])

;; ---------------------------------------------------------
;; first-of
(define-metafunction RTR-Base
  first-of : T -> T
  [(first-of (Pair T S)) T]
  [(first-of (Refine ([p : (Pair T S)]) Q)) T]
  [(first-of (∃ ([x : T] ...) S))
   (∃ ([x : T] ...) (first-of S))]
  [(first-of T) Any])

;; ---------------------------------------------------------
;; second-of
(define-metafunction RTR-Base
  second-of : T -> T
  [(second-of (Pair T S)) T]
  [(second-of (Refine ([p : (Pair T S)]) Q)) T]
  [(second-of (∃ ([x : T] ...) S))
   (∃ ([x : T] ...) (second-of S))]
  [(second-of T) Any])



;; ---------------------------------------------------------
;; Well-formedness
;; wf
(define-metafunction RTR-Base
  [(wf {[x : any] ...})
   ,(subset? (term (fv (any ...))) (term (x ...)))]
  [(wf (Env {{x : any} ...} Ψ))
   ,(and (subset? (term (fv Ψ)) (term (x ...)))
         (term (wf {{x : any} ...})))]
  [(wf (Env {{x : any_x} ...} Ψ) any)
   ,(and (subset? (term (fv any)) (term (x ...)))
         (subset? (term (fv Ψ)) (term (x ...)))
         (term (wf {{x : any_x} ...})))])

;; ---------------------------------------------------------
;; or
(define-metafunction RTR-Base
  or-macro : e ... -> e
  [(or-macro) false]
  [(or-macro e_1 e_2 ...)
   (let ([x e_1])
     (if x x (or-macro e_2 ...)))
   (where x ,(variable-not-in (term (e_1 e_2 ...)) 'fresh))])


(module+ test
  (display "base-lang.rkt tests complete!"))