#lang racket/base
(require pict
         ppict/pict
         plot/pict
         racket/string
         racket/match
         racket/format
         racket/class
         racket/system
         racket/cmdline)

;; which raco does the case study use on this machine
(define raco "/home/dave/racket-rtr/bin/raco")
;; folder where results should be stored (raw and summary)
(define result-folder "/home/dave/Desktop/case-study-output")


;; which libraries does our case study include
(define options '(math plot pict3d))

;; result
;; contains results of case study
(struct result (lib yes no) #:transparent)

;; results-file
;; file raw data is output for a given library
;; symbol -> string
(define (results-file lib)
  (format "~a/~a-output.csv"
          result-folder lib))

;; generate-output!
;; (listof symbol) -> void
;; reads results and generates the proper summary
(define (generate-output! libs)
  (define results (map tally-results libs))
  (generate-summary! results))

;; pretty-num
;; number -> number
;; make decimal percent 0.XYZ look like XY.Z
(define (pretty-num n)
  (/ (round (* n 1000.0))
     10.0))

;; tally-results
;; symbol -> result
;; reads the raw data generated from running test case on a lib
;; and produces a summary in a result struct
(define (tally-results lib)
  (define yes 0)
  (define no 0)
  (for ([line (in-lines (open-input-file (results-file lib)))])
    (cond
      [(string-contains? line ", YES ,") (set! yes (add1 yes))]
      [(string-contains? line ", NO ,") (set! no (add1 no))]))

  (result lib yes no))

;; result->text
;; result -> pict
;; pretty-formats a result object into a pict 
(define (result->text r)
  (match-define (result lib ys ns) r)
  (vl-append
   (text (format "~a library" lib))
   (text (format "~a out of ~a proven safe (~a %)"
                 ys (+ ys ns) (round (/ (* 100.0 ys) (+ ys ns)))))
   (colorize (rectangle 10 10) "white")))

;; generate-summary!
;; (listof result) -> void
;; takes a list of results and builds the histograms
;; and textual summaries and writes them to a file as a png
(define (generate-summary! results)
  ;; build the histogram
  (define hist
    (plot (list
           ;; success histogram
           (discrete-histogram
            (for/list ([r (in-list results)])
              (match-define (result lib ys _) r)
              (vector lib ys))
            #:skip 2.5 #:x-min 0
            #:label "Verified Safe" #:color 3 #:line-color 3)
           ;; failure histogram
           (discrete-histogram
            (for/list ([r (in-list results)])
              (match-define (result lib _ ns) r)
              (vector lib ns))
            #:skip 2.5 #:x-min 1 #:color 4 #:line-color 4
            #:label "Unable to Verify"))
          #:y-label "# of vector operation checks"
          #:x-label "Library"
          #:y-max (let ([v (max (apply max (map result-yes results))
                                (apply max (map result-no results)))])
                    (+ v (round (/ v 5))))
          #:title (~a "Provably Safe Vector Operations, Per Library\n")))
  ;; add the surrounding text
  (define bmap
    (pict->bitmap
     (ppict-do (filled-rectangle 725 450
                                 #:color "white"
                                 #:border-color "black")
               #:go (coord .97 .97 'rb)
               hist
               #:go (coord .03 .03 'lt)
               (text "RTR Case Study Results" '(bold))
               20
               (foldl vl-append
                      (rectangle 0 0)
                      (map result->text results)))))
  (define image-file
    (open-output-file (format "~a/~a-summary.png"
                              result-folder
                              (if (> (length results) 1)
                                  'all
                                  (result-lib (car results))))
                      #:exists 'replace))
  (send bmap save-file
        image-file
        'png
        100)
  (close-output-port image-file))




;; build-libs!
;; (listof symbol) -> void
;; run all commands w/ proper env variables
;; to perform case study
(define (build-libs! libs)
  ;; set env variable to report vector info
  (putenv "RTR_CASE_STUDY" "on")
  (for ([lib (in-list libs)])
    ;; clean the library
    (define cleaned?
      (let ([cmd (format "~a setup --clean ~a" raco lib)])
        (printf "executing: ~a\n" cmd)
        (system cmd)))
    (unless cleaned?
      (printf "unable to clean ~a" lib)
      (exit))
    ;; build the library
    (define built?
      (let ([cmd (format "~a setup -j 1 -D ~a 2> tee ~a"
                         raco lib (results-file lib))])
        (printf "executing: ~a\n" cmd)
        (system cmd)))
    (unless built?
      (printf "unable to build ~a\n" lib)
      (exit))))


;; *******************************************************************
;; MAIN
;; Running this file prompts the user for which libraries to build
;; and then runs the case study on those libraries and writes
;; out a summary to the result directory (specified above)

(printf "\n- - Safe Vector Operations Case Study - -\n")
(printf "Enter a target to build and check vector operations for:\n")
(for ([lib (in-list options)])
  (printf "    ~a\n" lib))
(printf "(or enter 'all' to build all three)\n")
(printf "> ")
(define user-input (read))

(cond
    [(member user-input (cons 'all options))
     (define libs
       (cond
         [(equal? 'all user-input)
          (build-libs! options)
          options]
         [else
          (define l (list user-input))
          (build-libs! l)
          l]))
     (printf "Libraries built!\n")
     (generate-output! libs)
     (printf "Raw data and a summary png can be found here:\n    ~a/\n"
             result-folder)]
    [else
     (printf "Sorry, unrecognized build target: ~a\n" user-input)])

(printf "bye!\n")