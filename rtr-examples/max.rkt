#lang typed/racket

(define-type Int Integer)

(: max : (~> ([x : Int] [y : Int])
             (Refine [z : Int]
                     (and (>= z x) (>= z y)))))
(define (max x y) (if (> x y) x y))

