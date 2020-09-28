;;; Model 1: Reitter Declarative model
(clear-all)

;;; --------- PARAMETERS ---------
(define-model model1 "A declarative model"

(sgp :seed (1 2)
     :er t; Enable randomness, how deterministically
     :esc t ; Subsymbolic computations
     :v nil
     :trace-detail low  ;high/medium/low
     :act t ; Activation trace
     :ans 0   ; acitvation noise
     :rt 0  ; threhsold
     ;:bbl 0.5   ; decay
     ;:lf 0.1    ; memory decay
     )

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
    language)

;;; --------- DM ---------
(add-dm
   (state) (wait) (next) (end) (yes) (no)
   (step1) (step2) (step3)  (step4)  (step5)  (step6)  (step7)
   (comprehend-sentence) (comprehend-picture)
   (syntactic-structure) (syn-corr) (syntax)
   (wait-for-screen isa goal-state state wait)
   (wait-for-next-screen isa goal-state state next)
   (DO-form ISA syntactic-structure syntax DO language english)
   (PO-form ISA syntactic-structure syntax PO language english)
   (s1 ISA sentence noun1 noun1 noun2 noun2 verb verb syntax DO syntax-corr no)
   (p1 ISA picture agent noun1 patient noun2 action verb)
)


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
    "retrieve DO"
    =goal>
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
        DO-form
    *goal>
        state next
    )

(p step3-2
    "retrieve PO"
    =goal>
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
        PO-form
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
        state step4

    +imaginal>
        ISA semantics
        agent =agent
        patient =patient
        action =action

    -retrieval>
    ;!output! ("in step 1-2 comprehend picture")
     )

(p step4
    "prepare to retrieve a syntax"
    =goal>
        ISA goal-state
        state step4

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
        state step5 
    
    =imaginal>

    +retrieval>
        ISA syntactic-structure
        ;syntax DO-form
        language english

)

(p step5-1
    "apply retrieved syntax"
    =goal>
        isa goal-state
        state step5

    ?retrieval>
        state free
        buffer full

    =retrieval>
         isa syntactic-structure
         language english
         syntax =syn

    =imaginal>
         isa semantics
         syntax nil

==>    
    *goal>
        state step6
    
    *imaginal>
        syntax =syn
)

(p step6-1
    "produce sentence DO"
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
    "produce sentence PO"
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
;(goal-focus wait-for-next-screen)
;(set-buffer-chunk 'visual 'p1)
)
