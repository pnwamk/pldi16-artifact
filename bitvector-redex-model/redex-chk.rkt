#lang racket/base
(require redex/reduction-semantics
         rackunit
         syntax/parse/define
         (for-syntax racket/base
                     syntax/parse))


(begin-for-syntax
  (define-splicing-syntax-class strict-test
    #:commit
    #:attributes (unit fail-unit)
    [pattern (~seq #:f t:test)
             #:attr unit #'t.fail-unit
             #:attr fail-unit #'t.unit]
    [pattern (~seq #:t a:expr)
             #:attr unit
             (syntax/loc #'a
               (check-not-false (term a)))
             #:attr fail-unit
             (syntax/loc #'a
               (check-false (term a)))]
    [pattern (~seq #:= a:expr b:expr)
             #:attr unit
             (syntax/loc #'a
               (check-equal? (term a) (term b)))
             #:attr fail-unit
             (syntax/loc #'a
               (check-not-equal? (term a) (term b)))])

  (define-splicing-syntax-class test
    #:commit
    #:attributes (unit fail-unit)
    (pattern c:strict-test
             #:attr unit #'c.unit
             #:attr fail-unit #'c.fail-unit)
    (pattern (c:strict-test)
             #:attr unit #'c.unit
             #:attr fail-unit #'c.fail-unit)
    [pattern (~seq a:expr b:expr)
             #:with (c:strict-test) (syntax/loc #'a (#:= a b))
             #:attr unit #'c.unit
             #:attr fail-unit #'c.fail-unit]
    [pattern (~seq a:expr)
             #:with (c:strict-test) (syntax/loc #'a (#:t a))
             #:attr unit #'c.unit
             #:attr fail-unit #'c.fail-unit])

  (define-splicing-syntax-class (rel-test rel)
    #:commit
    #:attributes (unit)
    [pattern (~and a [#:t args:expr ...])
             #:attr unit (quasisyntax/loc #'a (check-true (term (#,rel args ...))))]
    [pattern (~and a [#:f args:expr ...])
             #:attr unit (quasisyntax/loc #'a (check-false (term (#,rel args ...))))]
    [pattern (~and a [args:expr ...])
             #:attr unit (quasisyntax/loc #'a (check-true (term (#,rel args ...))))]))

(define-simple-macro (redex-chk e:test ...)
  (begin e.unit ...))

(define-syntax (redex-relation-chk stx)
  (syntax-parse stx
    [(_ relation:id
        (~var e (rel-test #'relation)) ...)
     #`(begin e.unit ...)]))



(provide redex-chk redex-relation-chk)

(module+ test
  (define-language Nats
    [Nat ::= Z (S Nat)])
  
  (define-metafunction Nats
    add2 : Nat -> Nat
    [(add2 Nat) (S (S Nat))])
  
  (define-judgment-form Nats
    #:mode (even I)
    #:contract (even Nat)
    [---------- "E-Zero"
     (even Z)]
    
    [(even Nat)
     ---------- "E-Step"
     (even (S (S Nat)))])

  (define-judgment-form Nats
    #:mode (equal-nats I I)
    #:contract (equal-nats Nat Nat)
    [---------- "Eq-Zero"
     (equal-nats Z Z)]
    
    [(equal-nats Nat_1 Nat_2)
     ---------- "Eq-Step"
     (equal-nats (S Nat_1) (S Nat_2))])
  
  (redex-chk
   Z Z
   #:f Z (S Z)
   #:t (even Z)
   #:f (even (S Z))
   #:f #:= (add2 Z) (S (S (S Z)))
   
   #:= (add2 (add2 (add2 Z)))
   (S (S (S (S (S (S Z))))))
   
   #:= (even (add2 (add2 (add2 Z))))
   (even (S (S (S (S (S (S Z)))))))
   
   #:f (even (S Z)))

  (redex-relation-chk
   even
   [#:t Z]
   [#:f (S Z)]
   [(S (S Z))])

  (redex-relation-chk
   equal-nats
   [#:t Z Z]
   [#:f (S Z) Z]
   [(S (S Z)) (add2 Z)]))