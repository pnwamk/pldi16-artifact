#lang scribble/manual

@title{Artifact: Occurrence Typing Modulo Theories}

@author{Andrew M. Kent, David Kempe, and Sam Tobin-Hochstadt}

This is the README for the artifact accompanying the
conditionally accepted paper "Occurrence Typing Modulo
Theories" (PLDI 2016).

@bold{Virtual Machine Details}

The virtual machine for this artifact is available in a .zip here:

Simply install this machine on your Virtual Box TODO MORE DETAILS.

The username is @tt{dave} and the password is @tt{artifact}.

@bold{Overview}

This artifact is composed of three key components:

@itemlist[#:style 'ordered
          @item{We have implemented Refined Typed Racket
           (RTR) with the theory of linear arithmetic atop
           Racket v6.2.1, allowing us to typecheck all the
           examples from the paper.}
          @item{Our PLT Redex model of the λ@subscript{RTR}
           formalism from the paper and a Redex model
           illustrating how bitvector theory is added (as
           discussed in sections 2.2 and 3.4) shows our
           approach is indeed agnostic of theory details and
           easily extended.}
          @item{Our case study examining vector accesses in
           three large Typed Racket libraries is
           reproducable. We include a script which generates
           the initial data for each of the libraries as
           well as our detailed analysis of the math library
           which allowed us to show almost 70% of vector
           accesses can be made provably safe with
           additional annotations and some relatively minor
           modifications.}]

The desktop of the virtual machine contains @bold{icons} which
will launch all of the key components of the artifact.

@section{RTR Implementation}

Our extension of Typed Racket v6.2.1 to implement RTR with
the theory of linear arithmetic is installed at the
following location:

@tt{/home/dave/racket-rtr}

@image["rtrexamples.png" #:scale .5]

@bold{RTR Examples} will launch a version of DrRacket using
the RTR back end and open all of the examples found in the
paper.

@section{λ@subscript{RTR} PLT Redex Models}

@margin-note{PLT Redex is a domain specific language for
 specifying and debugging formal systems. More information
 can be found here: https://redex.racket-lang.org/}

The PLT Redex models for the λ @subscript{RTR} formalism
described in our paper and its extension with bitvector
theory (described in sections 2.2 and 3.4) are found here:

@tt{/home/dave/pldi16-artifact-misc/base-redex-model}

@tt{/home/dave/pldi16-artifact-misc/bitvector-redex-model}

These are meant to be almost identical to the formal λ 
@subscript{RTR} described in our paper. Some small
modifications, like imposing an ordering on the logical
proves relation or using helper functions to keep things in
normal forms, are necessary if typechecking is to occur in a
reasonable amount of time.

@subsection{Base λ@subscript{RTR} Model}

@image["basemodel.png" #:scale .5]

@bold{RTR Base Redex Model} will launch DrRacket v6.4 and
open the primary files for the λ @subscript{RTR} base redex
model:

@itemlist[@item{@tt{base-lang.rkt} contains the redex
           language definition for λ@subscript{RTR}}
          @item{@tt{subtype.rkt} contains the subtype and
           logical proves relations which are described in
           the paper in figures 4 and 5. The file also
           contains a number of tests which execute when the
           "Run" button at the top right of DrRacket is
           pressed.}
          @item{@tt{well-typed.rkt} contains the typing
           judgment for λ@subscript{RTR} that is found in
           figure 3 of the paper. This file also contains a
           number of tests which can be executed using
           DrRacket's "Run" button.}]

@margin-note{DrRacket 6.4 is used to run our PLT Redex
 models and a few scripts, it will @bold{not} run examples
 from the paper using refinement types, etc.}

@subsection{λ@subscript{RTR}+Bitvector Theory Model}

@image["bitvectormodel.png" #:scale .5]

@bold{RTR Bitvector Redex Model} will launch DrRacket v6.4
and open the primary files for the λ
@subscript{RTR}+bitvector theory model. These files are
almost identical to those listed for the base
@subscript{RTR}, except they contain the additional forms
required for bitvector theory, as described in section 3.4
of the paper.

@image["bitvectordiff.png" #:scale .5]

@bold{View Bitvector Model Diff} will open the Meld diff
viewing program and make it easy to see the small number of
additions required to add bitvector theory to
λ@subscript{RTR}.

@image["modeldiffexample.png" #:scale .3]

@section{Case Study}

Our case study involved two phases:

@itemlist[#:style 'ordered
          @item{We used RTR with the theory of linear
           arithmetic to typecheck the math, plot, and
           pict3d libraries while checking if vector
           operations are verifiable without any additional
           annotations.}
          @item{We performed a detailed analysis on the math
           library results, assessing why various vector
           operations were not verifiable and investigating
           what reasonable changes could be made to make
           more operations provable safe.}]

@subsection{Case Study Part 1: Generating the Initial Data}

@image["runcasestudy.png" #:scale .5]

The first step for our case study can be replicated with
the @bold{Run Case Study} launcher. This runs our typechecker
on the unannotated math, plot, and pict3d libraries.

The raw data from this case study is written to files this
desktop folder:

@tt{/home/dave/Desktop/case-study-output}

A summary png is also generated in that location:

@image["casestudyresults.png" #:scale .4]

The examined libraries can all be found in the following
directory:

@tt{/home/dave/racket-rtr/extra-pkgs}

@subsection{Case Study Part 2: Math Libary Modifications}

The second half of our case study focused on examining the
output for the math library and seeing what annotations and
minor modifications could be made to make more vector
operations provably safe.

The modified version of the math library is found in here:

@tt{/home/date/racket-rtr-annotated-math/extra-pkgs/math}

@image["mathdiff.png" #:scale .5]

@bold{View Math Lib Diff} launches Meld to display the diff
between the original math library and the version after we
made our changes:

@image["mathdiffexample.png" #:scale .3]

@bold{Run Math Tests} will run the math library tests, showing
our changes did not break or change the library's behavior.

@image["runmathtests.png" #:scale .5]

During this effort, we performed a detailed examination of
all of the raw vector data generated in the first half of
the case study. As we made modifications and converted more
vector operations to their safe counterparts, we recorded
our updates and analysis in the following spreadsheet:

@tt{/home/dave/Desktop/math-detailed-summary}

After making changes and examining the data in more detail
we found almost 70% of all unique vector operations could be
made provably safe with our system (this number is slightly
smaller than that reported in the paper because of a few
bugs and corrections made after our initial submission).

@section{Miscellaneous}

All of the desktop launchers point to scripts contained here:

@tt{/home/dave/pldi16-artifact-misc/scripts}

That folder also contains scripts which can be used to add
the racket/bin directory of the various installs to the
current PATH.

For example, running @tt{source
 /home/dave/pldi16-artifact-misc/add-racket-rtr-to-path.sh}
in a terminal would add the RTR installation to the current
terminal's PATH.
