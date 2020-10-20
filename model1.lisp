;;; Model 1: Reitter Declarative model
(clear-all)

;;; --------- PARAMETERS ---------
(define-model model1 "A declarative model"

(sgp ;:seed (200 20)
     :er t; Enable randomness, how deterministically
     :esc t ; Subsymbolic computations
     :v nil
     :trace-detail low  ;high/medium/low
     :act t         ; Activation trace
     ;:show-focus t  ; Debug focus of visual
     :ans 0.1        ; acitvation noise
     ;:rt -100      ; threhsold
     :bll 0.1      ; decay
     :lf 0.1        ; memory decay
     :mas 1.6       ;
     :imaginal-activation 1.0
     )
(sgp :style-warnings nil)


;;; --------- CHUNK TYPE ---------
(chunk-type goal-state
    state)
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
   (syntactic-structure) (syn-corr) (syntax) (DO) (PO) (english)
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
        noun1 =n1
        noun2 =n2
        verb =verb
        syntax =syntax
        syntax-corr =syntax-corr
==>
    =visual>

    *goal>
        state step2

    +imaginal>
        ISA semantics
        agent =n1
        patient =n2
        action =verb
        syntax =syntax
        syntax-corr =syntax-corr

    ;!output! ("in step 1")
    ;!output! (the syntax is =syntax =syntax-corr)
     )


(p step2-1
    "comprehend successfully, create a semantic representation"
    =goal>
        ISA goal-state
        state step2
    ?imaginal>
        state free
    =imaginal>
        ISA semantics
        syntax-corr yes

==>
    =imaginal>
    *goal>
        state step3
    )

(p step2-2
    "fail to comprehend, wait for picture"
    =goal>
        ISA goal-state
        state step2
    ?imaginal>
        state free
    =imaginal>
        ISA semantics
        syntax-corr no
==>
    -imaginal>
    *goal>
        state next
    )

(p step3-1
    "request a retrieval of DO"
    =goal>
        ISA goal-state
        state step3
    ?imaginal>
        state free
    =imaginal>
        ISA semantics
        syntax DO
        syntax-corr yes
    ?retrieval>
        state free
        buffer empty
==>
    +retrieval>
        ISA syntactic-structure
        syntax DO
        english t
    *goal>
        state step4
    )

(p step3-2
    "request a retrieval of PO"
    =goal>
        ISA goal-state
        state step3
    ?imaginal>
        state free
    =imaginal>
        ISA semantics
        syntax PO
        syntax-corr yes
    ?retrieval>
        state free
        buffer empty
==>
    +retrieval>
        ISA syntactic-structure
        syntax PO
        english t
    *goal>
        state step4
    )

(p step4-1
    "successfully retrieved"
    =goal>
        ISA goal-state
        state step4
    =retrieval>
        ISA syntactic-structure
        - syntax nil
        english t
==>
    *goal>
        state next
    )

(p step4-2
    "failed to retrieve"
    =goal>
        ISA goal-state
        state step4
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
        buffer empty

    =visual>
        ISA picture
        agent =agent
        patient =patient
        action =action
==>
    *goal>
        state step5

    +imaginal>
        ISA semantics
        agent =agent
        patient =patient
        action =action
    ;!output! ("in step 1-2 comprehend picture")
     )

(p step5-1
    "spread activation to DO"
    =goal>
        ISA goal-state
        state step5

    ?imaginal>
        state free
        buffer full

    =imaginal>
        syntax nil
==>
    =imaginal>
        syntax DO
    *goal>
        state step5-3
    )

(p step5-2
    "spread activation to PO"
    =goal>
        ISA goal-state
        state step5

    ?imaginal>
        state free
        buffer full

    =imaginal>
        syntax nil
==>
    =imaginal>
        syntax PO
    *goal>
        state step5-3
    )

(p step5-3
    "no spreading"
    =goal>
        ISA goal-state
        state step5

    ?imaginal>
        state free
        buffer full

    =imaginal>
        syntax nil
==>
    =imaginal>

    *goal>
        state step5-3
    )

(p step5-4
    "prepare to retrieve any syntax"
    =goal>
        ISA goal-state
        state step5-3

    ?imaginal>
        state free
        buffer full

    =imaginal>
        ISA semantics
        agent =agent
        patient =patient
        action =action

    ?retrieval>
        state free
        buffer empty

==>
    *goal>
        state step6
    
    =imaginal>

    +retrieval>
        ISA syntactic-structure
        english t
)


(p step6-1
    "sucessfully retrieved syntax and apply it"
    =goal>
        isa goal-state
        state step6

    ?retrieval>
        state free
        buffer full

    =retrieval>
         isa syntactic-structure
         english t
         syntax =syn

    =imaginal>
         isa semantics
         ; syntax =syn

==>    
    =imaginal>
        syntax =syn
    *goal>
        state step7

)

(p step6-2
    "failed to retrieve any syntax, apply failure to imaginal buffer"
    =goal>
        isa goal-state
        state step6

    ?retrieval>
        buffer failure

    =imaginal>
         isa semantics
==>    
    *goal>
        state step7
    
    =imaginal>
        syntax failure
)


(p step7-1
    "produce sentence DO"
    =imaginal>
        isa semantics
        syntax DO
    
    =goal>
        ISA goal-state
        state step7

    ?vocal>
        state free
==>
    *goal>
        state end

    +vocal>
        cmd speak
        string "DO"
)

(p step7-2
    "produce sentence PO"
    =imaginal>
        isa semantics
        syntax PO
    
    =goal>
        ISA goal-state
        state step7

    ?vocal>
        state free
==>
    *goal>
        state end

    +vocal>
        cmd speak
        string "PO"
)

(p step7-3
    "fail to produce any syntactic structure"
    =imaginal>
        isa semantics
        syntax failure
    
    =goal>
        ISA goal-state
        state step7

    ?vocal>
        state free
==>
    *goal>
        state end

    +vocal>
        cmd speak
        string "failure"
)

)
