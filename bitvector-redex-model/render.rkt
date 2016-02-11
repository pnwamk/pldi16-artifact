#lang racket

(require redex
         "base-lang.rkt"
         "base-helpers.rkt"
         "subtype.rkt"
         "subtype-helpers.rkt"
         "well-typed.rkt"
         typeset-rewriter
         pict)

(define subtype-cases
  (list "S-Refl"
        "S-Top"
        "S-UnionSub"
        "S-UnionSuper"
        "S-RefineWeaken"
        "S-RefineSub"
        "S-RefineSuper"
        "S-Fun"
        "S-Pair"
        "S-Result"
        "S-ExistsSub"))

(define proves-cases
  (list "L-Refl"
        "L-Subtype"
        "L-SubtypeNot"
        "L-NoOverlap"
        "L-True"
        "L-False"
        "L-Absurd"
        "L-Bot"
        "L-AndE"
        "L-AndI"
        "L-OrE"
        "L-OrI"
        "L-DeM1"
        "L-DeM2"
        "L-AliasE"
        "L-Identity"
        "L-RefineE"
        "L-RefineI"
        "L-RefineINot"
        "L-ExistsType"
        "L-ExistsProp"
        "L-Update"
        "L-UpdateNot"
        "L-Theory"))

(define wt-cases
  (list "T-Val"
        "T-Var"
        "T-Abs"
        "T-App"
        "T-If"
        "T-Let"
        "T-Pair"
        "T-First"
        "T-Second"
        "T-Clos"))

(define typeof-rw
  (rw-lambda
   [`(@ ,x ,o) => (list "(" x " -: " o ")")]))
(define alias-rw
  (rw-lambda
   [`(↦ ,x ,o) => (list "(" x " ↦ " o ")")]))
(define result-rw
  (rw-lambda
   [`(Result ,t ,p ,q) => (list "⟨" t " ; " p " | " q "⟩")]))
(define pair-rw
  (rw-lambda
   [`(Pair ,t ,s) => (list "(" t " × " s ")")]))
(define pair*-rw
  (rw-lambda
   [`(Pair* ,t ,s) => (list "(" t " × " s ")")]))
(define refine-rw
  (rw-lambda
   [`(Refine ([,x : ,t]) ,p) => (list "{" x " : " t " | " p "}")]))
(define refine*-rw
  (rw-lambda
   [`(Refine* ([,x : ,t]) ,p) => (list "{" x " : " t " | " p "}")]))
(define env-rw
  (rw-lambda
   [`(Env ,e1 ,e2) => (list "⟨" e1 ";" e2 "⟩")]))
(define union-rw
  (rw-lambda
   [`(U) => (list "⊥")]
   [`(U ,ts ...) => (append (cons "(∪ " ts) (list ")"))]))
(define union*-rw
  (rw-lambda
   [`(U* ,ts ...) => (append (cons "(∪ " ts) (list ")"))]))
(define conjunction-rw
  (rw-lambda
   [`(And ,ps ...) => (append (cons "(∧ " ps) (list ")"))]))
(define disjunction-rw
  (rw-lambda
   [`(Or ,ps ...) => (append (cons "(∨ " ps) (list ")"))]))
(define conjunction:-rw
  (rw-lambda
   [`(And: ,ps ...) => (append (cons "(∧ " ps) (list ")"))]))
(define disjunction:-rw
  (rw-lambda
   [`(Or: ,ps ...) => (append (cons "(∨ " ps) (list ")"))]))
(define fun-rw
  (rw-lambda
   [`(Fun ,doms -> ,rng) => (list "" doms " → " rng "")]))
(define let-rw
  (rw-lambda
   [`(let ([,x ,ex]) ,e) => (list "(let (" x " " ex ") " e")")]))
(define exists-rw
  (rw-lambda
   [`(∃ ,doms ,body) => (list "∃" doms "(" body ")")]))
(define exists:-rw
  (rw-lambda
   [`(∃: ,doms ,body) => (list "∃" doms "(" body ")")]
   [`(∃: ,doms ,body1 ,body2 ,body3)
    => (list "∃" doms "(" body1  ";" body2 ";" body3 ")")]))
(define lambda-rw
  (rw-lambda
   [`(λ ,doms ,body) => (list "(λ" doms " " body ")")]))
(define neq-rw
  (rw-lambda
   [`(<> ,lhs ,rhs) => (list "" lhs " ≠ " rhs)]))
(define lookup-rw
  (rw-lambda
   [`(lookup ,env ,o) => (list "" env "(" o ")")]))
(define neg-rw
  (rw-lambda
   [`(¬ ,p)
    => (list "¬" p )]))
(define no-overlap-rw
  (rw-lambda
   [`(no-overlap ,t ,s)
    => (list "∄v. ⊢ v : " t " and ⊢ v : " s)]))
(define obj-path-rw
  (rw-lambda
   [`(obj-path ,o)
    => (list "path(" o ")")]))
(define obj-id-rw
  (rw-lambda
   [`(obj-id ,o)
    => (list "id(" o ")")]))
(define val-type-rw
  (rw-lambda
   [`(val-type ,v)
    => (list  "δ-τ(" v ")")]))
(define select-type-rw
  (rw-lambda
   [`(select-type ,env ,x)
    => (list "select-type(" env "," x ")")]))
(define update-env-rw
  (rw-lambda
   [`(update-env ,e ,pm ,o ,t)
    => (list "update-Δ(" e "," pm "," o "," t ")")]))
(define update-rw
  (rw-lambda
   [`(update ,e ,t1 ,pth ,pm ,t2)
    => (list "update(" e "," t1 "," pth
             "," pm "," t2 ")")]))
(define restrict-rw
  (rw-lambda
   [`(restrict ,e ,t ,s)
    => (list "restrict(" e "," t "," s ")")]))
(define remove-rw
  (rw-lambda
   [`(remove ,e ,t ,s)
    => (list "remove(" e "," t "," s ")")]))
(define subtype-rw
  (rw-lambda
   [`(subtype ,env ,t1 ,t2)
    => (list "" env " ⊢ " t1 " <: " t2)]))
(define proves-rw
  (rw-lambda
   [`(proves ,env ,p)
    => (list "" env " ⊢ " p)]))
(define PROVES-rw
  (rw-lambda
   [`(PROVES ,env ,p)
    => (list "" env " ⊢ " p)]))
(define wt-rw
  (rw-lambda
   [`(wt ,env ,e ,R)
    => (list "" env " ⊢ " e " : " R)]))
(define wt-T-rw
  (rw-lambda
   [`(wt-T ,env ,e ,t)
    => (list "" env " ⊢ " e " : " t)]))
(define subst-rw
  (rw-lambda
   [`(subst ,env (,subst))
    => (list "" env "" subst)]
   [`(subst ,env ,substs)
    => (list "" env "" substs)]))
(define ext-rw
  (rw-lambda
   [`(ext ,env ,a)
    => (list "" env ", " a)]
   [`(ext ,env ,a ,b)
    => (list "" env ", " a ", " b)]
   [`(ext ,env ,a ,b ,c)
    => (list "" env ", " a ", " b ", " c)]))


(define-rw-context
  with-rtr-rws
  #:atomic (['Res "𝕽"]
            ['T "τ"]
            ['S "σ"]
            ['P "ψ"]
            ['Q "φ"]
            ['R "χ"]
            ['Any "⊤"]
            ['<= "<="]
            ['* "∗"]
            ['pos "+"]
            ['neg "-"]
            ['fst "first"]
            ['snd "second"]
            ['first "fst"]
            ['second "snd"]
            ['true "#t"]
            ['false "#f"]
            ['True "♯T"]
            ['False "♯F"])
  #:compound (['@ typeof-rw]
              ['↦ alias-rw]
              ['Result result-rw]
              ['U union-rw]
              ['U* union*-rw]
              ['Pair pair-rw]
              ['Refine refine-rw]
              ['Pair* pair*-rw]
              ['Refine* refine*-rw]
              ['Fun fun-rw]
              ['And conjunction-rw]
              ['Or disjunction-rw]
              ['And: conjunction:-rw]
              ['Or: disjunction:-rw]
              ['let let-rw]
              ['Env env-rw]
              ['∃ exists-rw]
              ['∃: exists:-rw]
              ['λ lambda-rw]
              ['subtype subtype-rw]
              ['proves proves-rw]
              ['PROVES PROVES-rw]
              ['subst subst-rw]
              ['ext ext-rw]
              ['lookup lookup-rw]
              ['¬ neg-rw]
              ['no-overlap no-overlap-rw]
              ['<> neq-rw]
              ['obj-path obj-path-rw]
              ['obj-id obj-id-rw]
              ['val-type val-type-rw]
              ['select-type select-type-rw]
              ['update-env update-env-rw]
              ['update update-rw]
              ['restrict restrict-rw]
              ['remove remove-rw]
              ['wt wt-rw]
              ['wt-T wt-T-rw]))

(define (lang-pict)
  (with-rws
   #:atomic (['n "n ∈ ℤ"]
             ['X "X ∈ Theory[i]"])
   (with-rtr-rws
    (scale (render-language
            RTR-Base
            #:nts '(p v e field o T S Res A P Q R Γ Ψ Δ))
           1.5))))

(define-syntax-rule (define-judgment-drawer
                      NAME
                      JUDGMENT
                      RULE-LIST
                      DEFAULT-SIZE
                      DEFAULT-COLS)
  (define (NAME #:scale [size DEFAULT-SIZE] #:cols [cols DEFAULT-COLS])
    (define rule-vec (make-vector cols null))
    (for ([(rule i) (in-indexed (in-list (reverse RULE-LIST)))])
      (define i-mod-cols (modulo i cols))
      (vector-set! rule-vec i-mod-cols
                   (cons rule (vector-ref rule-vec i-mod-cols))))
    (label-style '(caps))
    (define init-img
      (begin (judgment-form-cases (vector-ref rule-vec 0))
             (scale (with-rtr-rws (render-judgment-form
                                   JUDGMENT))
                    size)))
    (for/fold ([img init-img])
              ([i (in-range 1 (vector-length rule-vec))])
      (hc-append 15 img
                 (begin (judgment-form-cases (vector-ref rule-vec i))
                        (scale (with-rtr-rws (render-judgment-form
                                              JUDGMENT))
                               size))))))

(define-judgment-drawer subtype-pict subtype subtype-cases 1.5 2)
(define-judgment-drawer proves-pict PROVES proves-cases 1.5 2)
(define-judgment-drawer wt-pict wt wt-cases 1.5 2)

(define (update-env-pict)
  (metafunction-pict-style
   'left-right/vertical-side-conditions)
  (with-rtr-rws
   (scale
    (render-metafunction
     update-env)
    1.5)))

(define (update-pict)
  (metafunction-pict-style
   'left-right/vertical-side-conditions)
  (with-rtr-rws
   (scale
    (render-metafunction
     update)
    1.5)))

(define (restrict-pict)
  (metafunction-pict-style
   'left-right/vertical-side-conditions)
  (with-rtr-rws
   (scale
    (render-metafunction
     restrict)
    1.5)))

(define (remove-pict)
  (metafunction-pict-style
   'left-right/vertical-side-conditions)
  (with-rtr-rws
   (scale
    (render-metafunction
     remove)
    1.5)))

(define (restrict/remove-pict)
  (ht-append 15 (restrict-pict) (remove-pict)))

;; TODO
;; wt
;; wt-T
;; val-type
;; theory-of
;; provable-in-theory
;; wf?
;; path?
;; id?
