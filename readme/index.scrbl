#lang scribble/manual

@(require)

@title{Artifact: Occurrence Typing Modulo Theories}

@author{Andrew M. Kent, David Kempe, and Sam Tobin-Hochstadt}

This is a README for the artifact accompanying the
conditionally accepted paper "Occurrence Typing Modulo
Theories" (PLDI 2016).

The virtual machine for this artifact is available in a .zip here:

Simply install this machine on your Virtual Box TODO MORE DETAILS.

The username is `dave' and the password is `artifact'.

This artifact contains the following:

@itemlist[@item{An implementation of Refined Typed Racket
           (RTR) atop Typed Racket v6.2.1, including support
           for the theory of linear arithmetic and examples
           from the paper.}
          @item{A PLT Redex model of the λ@subscript{RTR}
           formal language found in the paper, along with a
           Redex model of the bitvector extension discussed
           in sections 2.2 and 3.4.}
          @item{Details for replicating and examing the
           results of our vector operations case study,
           including a script which performs the initial
           analysis as well as detailed information
           regarding our work on the math library.}]

@section{RTR Implementation}

The implementation of RTR + the theory of linear arithmetic
we built on top of Typed Racket v6.2.1 is installed at the
following location:

/home/dave/racket-rtr

@image["rtrexamples.png" #:scale .5]

The desktop launcher "RTR Examples" will launch DrRacket
backed with this Racket installation, opening all of the examples
found in the paper.

This implementation is what we used to add dependent
refinement types to the math library, which we describe in
more detail below.

@section{λ@subscript{RTR} PLT Redex Models}

The PLT Redex models for the λ@subscript{RTR} formalism
described in our paper and its extension with bitvector
theory (described in sections 2.2 and 3.4) is found here:

/home/dave/pldi16-artifact-misc/base-redex-model

and here respectively:

/home/dave/pldi16-artifact-misc/bitvector-redex-model

These is meant to be almost identical to the formal λ
@subscript{RTR} described in our paper. Some small
modifications, like forcing an ordering for the proves
relation so it is fully algorithmic, are necessary if
typechecking is to occur in a reasonable amount of time.

@subsection{Base λ@subscript{RTR} Model}

@image["basemodel.png" #:scale .5]

The desktop launcher "RTR Base Redex Model" will launch
DrRacket v6.4 and open the primary files for the λ
@subscript{RTR} base redex model:

@itemlist[@item{base-lang.rkt contains the redex language
           definition for λ@subscript{RTR}}
          @item{subtype.rkt contains the subtype and
           logical derivation relations which are described
           in the paper in figures 4 and 5. The file also
           contains a number of tests which execute when the
           "Run" button at the top right of DrRacket is
           pressed.}
          @item{well-typed.rkt contains the typing judgment
           for λ@subscript{RTR} that is found in figure 3
           of the paper. This file also contains a number of
           tests which can be run.}]

@subsection{λ@subscript{RTR}+Bitvector Theory Model}

@image["bitvectormodel.png" #:scale .5]

The desktop launcher "RTR Bitvector Redex Model" will launch
DrRacket v6.4 and open the primary files for the λ 
@subscript{RTR}+bitvector theory model. These files are
almost identical to those listed above, except that they
contain the additional forms required for bitvector theory,
as described in section 3.4 of the paper.

@image["bitvectordiff.png" #:scale .5]

The desktop launcher "View Bitvector Model Diff" will open
the Meld diff viewing program and make it easy to see the
additions required to add bitvector theory to
λ@subscript{RTR}.

@image["modeldiffexample.png" #:scale .5]

@section{Case Study}

Our case study first involved having RTR typecheck the
math, plot, and pict3d libraries while checking if vector
operations were verifiable without any additional
annotations. We then performed a more detailed analysis on
the math library, which involved modifications and
annotations to use more safe vector operations.

@subsection{Case Study Part 1: Generating the Initial Data}

@image["runcasestudy.png" #:scale .5]

The initial step for our case study can be replicated with
the desktop launcher "Run Case Study". This runs our typechecker
on the unannotated math, plot, and pict3d libraries.

The raw data from this case study is printed to the terminal
during execution and stored in the following folder:

/home/dave/Desktop/case-study-output

along with a summary png:

@image["casestudyresults.png" #:scale .5]

The above mentioned libraries can all be found in the
following directory:

/home/dave/racket-rtr/extra-pkgs

@subsection{Case Study Part 2: Math Libary Modifications}

The second half of our case study focused on adding
annotations and making small changes to the math library in
order to use more provably safe vector references.

This annotated library is found here:

/home/date/racket-rtr-annotated-math/extra-pkgs/math

@image["mathdiff.png" #:scale .5]

The desktop launcher "View Math Lib Diff" uses Meld
to display the diff between the original math library
and the version after we made our changes:

@image["mathdiffexample.png" #:scale .5]

The "Run Math Tests" launcher will test the math library,
showing our changes did not break or change the library's
external specification.

@image["runmathtests.png" #:scale .5]


While making these changes, we performed a detailed
examination of all of the raw vector data generated in the
first half of the case study. As we made modifications and
converted more vector operations to their safe counterparts,
we recorded our updates and analysis in the following
spreadsheet:

/home/dave/Desktop/math-detailed-summary

After making changes and examining the data in more detail
we came to find 68% of all unique vector operations could be made
provably safe with our system (this number is slightly
smaller than that reported in the paper because of a few
bugs and corrections made after our initial submission).

@section{Miscellaneous}

All of the desktop launchers point to scripts contained here:

/home/dave/pldi16-artifact-misc/scripts

That folder also contains scripts which can be used to add
the racket/bin directory of the various installs to the
current PATH.

For example, entering `source
/home/dave/pldi16-artifact-misc/add-racket-rtr-to-path.sh'
would add the RTR installation to the current terminal's
PATH.
