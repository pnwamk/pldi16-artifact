#lang typed/racket

;; Basic occurrence typing example from
;; section 2 of "Occurrence Typing Modulo Theories"


(define-type Bit (U Zero One))

(: least-significant-bit :
    (U Integer (Listof Bit)) -> Bit)
  (define (least-significant-bit n)
    (if (exact-integer? n)
        (if (even? n) 0 1)
        (last n)))


