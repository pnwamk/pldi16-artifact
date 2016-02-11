#lang typed/racket

(: least-significant-bit :
    (U Int (Listof Bit)) -> Bit)
  (define (least-significant-bit n)
    (if (int? n)
        (if (even? n) 0 1)
        (last n)))


