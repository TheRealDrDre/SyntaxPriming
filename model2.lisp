;;; Model 2: Surprisal model
;;;####################################################################################################################
;;; Summary of Model
; The model2 accounts for the low-frequency priming effects
;
;
; First, the model parses in prime sentence from visual buffer (step1-1)
; Then it requests a retrieval of either DO/PO based on prime (step2)
; After successfully retrieves (step3-1) or failed to retrieve(step3-2), the model proceeds to the picture description
;       task, parsing in the target picture from visual buffer (step1-2)
; Then the model requests a retrieval of any available syntactic structure(step4)
; Given the retrieval outcomes, the model applies the syntactic structure (step5-1), or the model fails to retrieve any
;       syntax (step5-2)
; Lastly, the model speaks out the syntactic structure DO(step6-1), PO(step6-2), or unknown(step6-3)
;       to simulate the process of producing a full sentence
;
;;; Notes: one additional parameter is set the base level for DO-FORM to create a bias for DO constructions.
;;;####################################################################################################################


(clear-all)

;;; --------- PARAMETERS ---------
(define-model model2 "A surprisal model"

(sgp ;:seed (250 20)
     :er t; Enable randomness, how deterministically
     :esc t                 ; Subsymbolic computations
     :v nil
     :trace-detail low      ;high/medium/low
     :act t                 ; Activation trace
     ;:show-focus t         ; Debug focus of visual
     :ans 0.5                ; Activation noise
     ;:egs 0.01             ; Utility noise parameter
     :rt -100              ; Threshold
     :bll 0.5               ; Decay
     :lf 1.0               ; Memory decay
     :mas 3.2               ; Maximum activation strength
     :ga 1                  ; Spreading from goal buffer
     :imaginal-activation 0 ; Spreading from imaginal buffer
     )
(sgp :style-warnings nil)


;;; --------- CHUNK TYPE ---------
(chunk-type goal-state
    state
    spread-syntax)
(chunk-type sentence
    string
    noun1
    noun2
    verb
    syntax
    syntax-corr)
(chunk-type semantics
    agent
    patient
    action
    syntax
    syntax-corr)
(chunk-type picture
    agent
    patient
    action)
(chunk-type syntactic-structure
    syntax
    english)


;;; --------- DM ---------
(add-dm
   (state) (wait) (next) (end) (yes) (no)
   (step1) (step2) (step3)  (step4)  (step5) (step6)  (step7)
   (comprehend-sentence) (comprehend-picture)
   (syntactic-structure) (syn-corr) (syntax) (spread-syntax)
   (DO) (PO) (unknown)(english)
   (wait-for-screen isa goal-state state wait)
   (wait-for-next-screen isa goal-state state next)
   (DO-form ISA syntactic-structure syntax DO english t)
   (PO-form ISA syntactic-structure syntax PO english t)
)



; ----- BIAS toward DO ----
;(set-base-levels (DO-form 1) (PO-form 0))

;;;---------------- COMPREHEND ----------------
(p step1-1
    "parse in the prime sentence, create a semantic representation in imaginal buffer"
    =goal>
        ISA goal-state
        state wait

    ?imaginal>
        state free
        buffer empty

    =visual>
        ISA sentence
        ; noun1 =n1
        ; noun2 =n2
        ; verb =verb
        syntax =syntax
        syntax-corr =syntax-corr
==>
    =visual>

    *goal>
        state step2

    +imaginal>
        ISA semantics
        ; agent =n1
        ; patient =n2
        ; action =verb
        syntax =syntax
        syntax-corr =syntax-corr

    ;!output! ("in step 1")
    ;!output! (the syntax is =syntax =syntax-corr)
     )

(p step2
    "request a retrieval of syntactic structure(DO/PO) based on prime"
    =goal>
        ISA goal-state
        state step2
    ?imaginal>
        state free
    =imaginal>
        ISA semantics
        syntax =syntax
    ?retrieval>
        state free
        buffer empty

==>
    =imaginal>
    *goal>
        state step3

    +retrieval>
        ISA syntactic-structure
        syntax =syntax
        english t
    )


(p step3-1
    "successfully retrieved"
    =goal>
        ISA goal-state
        state step3
    =retrieval>
        ISA syntactic-structure
        - syntax nil
        syntax =syn
        english t
==>
    *goal>
        state next
    )

(p step3-2
    "failed to retrieve"
    =goal>
        ISA goal-state
        state step3
    ?retrieval>
        buffer failure
==>
    *goal>
        state next
    )


;------------- PRODUCTION -------------
(p step1-2
    "parse in the target picture, create a semantic representation in imaginal buffer"
    =goal>
        ISA goal-state
        state next

    ?imaginal>
        state free
        ; buffer empty

    =imaginal>
        - syntax nil ; prime syntax
        syntax =syn

    =visual>
        ISA picture
        ;agent =agent
        ;patient =patient
        ;action =action
==>
    *goal>
        state step4

    *imaginal>
        ; agent =agent
        ; patient =patient
        ; action =action
     !output! ("in step 1-2 comprehend picture, in imaginal")
     !output! =syn
     )


(p step4-1
    "if find no error(high-freq construction), no spreading activation
    and request a retrieval of any syntactic structure"
    =goal>
        ISA goal-state
        state step4

    ?imaginal>
        state free
        buffer full

    =imaginal>
        ISA semantics
        - syntax nil
        syntax =syn
        syntax-corr yes
        ; agent =agent
        ; patient =patient
        ; action =action

    ?retrieval>
        state free
        buffer empty

==>
    *goal>
        state step5

    -imaginal>

    +retrieval>
        ISA syntactic-structure
        english t
    ; !output! ('in imaginal' =syn)
)

(p step4-2
    "if find error(low-freq construction), spreading activation to this structure
    and request a retrieval of any syntactic structure"
    =goal>
        ISA goal-state
        state step4

    ?imaginal>
        state free
        buffer full

    =imaginal>
        ISA semantics
        - syntax nil
        syntax =syn
        syntax-corr no
        ; agent =agent
        ; patient =patient
        ; action =action

    ?retrieval>
        state free
        buffer empty

==>
    *goal>
        state step5
        spread-syntax =syn ; prime syntax

    -imaginal>

    +retrieval>
        ISA syntactic-structure
        english t
    ; !output! ('in imaginal' =syn)
)

(p step5-1
    "sucessfully retrieved syntax and apply it"
    =goal>
        isa goal-state
        state step5

    ?retrieval>
        state free
        buffer full

    =retrieval>
         isa syntactic-structure
         english t
         syntax =syn

    ?imaginal>
        state free
        buffer empty


==>
    *goal>
        state step6

    +imaginal>
        isa semantics
        syntax =syn

)

(p step5-2
    "failed to retrieve any syntax, apply failure to imaginal buffer"
    =goal>
        isa goal-state
        state step5

    ?retrieval>
        buffer failure

    ?imaginal>
        state free
        buffer empty

==>
    *goal>
        state step6

    +imaginal>
        isa semantics
        syntax unknown

)


(p step6-1
    "produce DO sentence"
    =imaginal>
        isa semantics
        syntax DO

    =goal>
        ISA goal-state
        state step6

    ?vocal>
        state free
==>
    *goal>
        state end

    +vocal>
        cmd speak
        string "DO"
)

(p step6-2
    "produce PO sentence"
    =imaginal>
        isa semantics
        syntax PO

    =goal>
        ISA goal-state
        state step6

    ?vocal>
        state free
==>
    *goal>
        state end

    +vocal>
        cmd speak
        string "PO"
)

(p step6-3
    "failed to produce sentence"
    =imaginal>
        isa semantics
        syntax unknown

    =goal>
        ISA goal-state
        state step6

    ?vocal>
        state free
==>
    *goal>
        state end

    +vocal>
        cmd speak
        string "unknown"
)
)