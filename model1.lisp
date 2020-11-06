;;; Model 1: Reitter Declarative model
;;;####################################################################################################################
;;; Summary of Model
; The model1 relies on retrieval module to decide syntactic structure
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
(define-model model1 "A declarative model"

(sgp ;:seed (250 20)
     :er t; Enable randomness, how deterministically
     :esc t                 ; Subsymbolic computations
     :v nil
     :style-warnings nil
     :model-warnings nil
     :trace-detail low      ;high/medium/low
     :act t                 ; Activation trace
     :ans .5              ; Activation noise
     :bll 0.5               ; Decay
     :lf 1.0                ; Memory decay
     ;:rt -1000              ; Threshold
     )

;;; --------- CHUNK TYPE ---------
(chunk-type goal-state
    state
    retrieved-syntax)
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
   (syntactic-structure) (syn-corr) (syntax) (retrieved-syntax) 
   (DO) (PO) (unknown)(english)
   (wait-for-screen isa goal-state state wait)
   (wait-for-next-screen isa goal-state state next)
   (DO-form ISA syntactic-structure syntax DO english t)
   (PO-form ISA syntactic-structure syntax PO english t)
)



; ----- BIAS toward DO ----
(set-base-levels (DO-form 1) (PO-form 0))

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
        - syntax nil
        syntax =syn

    =visual>
        ISA picture
        agent =agent
        patient =patient
        action =action
==>
    *goal>
        state step4

    *imaginal>
        ; agent =agent
        ; patient =patient
        ; action =action
    ; !output! ("in step 1-2 comprehend picture, in imaginal")
    ; !output! =syn
     )


(p step4
    "request a retrieval of any syntactic structure"
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
        ; agent =agent
        ; patient =patient
        ; action =action 

    ?retrieval>
        state free
        buffer empty

==>
    *goal>
        state step5
    
    =imaginal>

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

==>    
    *goal>
        state step6
        retrieved-syntax =syn
)

(p step5-2
    "failed to retrieve any syntax, apply failure to imaginal buffer"
    =goal>
        isa goal-state
        state step5

    ?retrieval>
        buffer failure

==>    
    *goal>
        state step6
        retrieved-syntax unknown
)


(p step6-1
    "produce DO sentence"
    =imaginal>
        isa semantics
        - syntax nil
    
    =goal>
        ISA goal-state
        state step6
        retrieved-syntax DO

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
        - syntax nil
    
    =goal>
        ISA goal-state
        state step6
        retrieved-syntax PO

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
        - syntax nil
    
    =goal>
        ISA goal-state
        state step6
        retrieved-syntax unknown

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