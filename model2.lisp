;;; Model 2: A pure RL model for DO/PO
;;;####################################################################################################################
;;; Summary of Model
; The model1 relies on production module(pure RL) to decide syntactic structure
;
;
; First, the model parses in prime sentence from visual buffer (step1-1)
;       and creates a mental representation in imaginal buffer
; If model parses in DO prime, it chooses DO(step2-1); otherwise, it chooses PO(step2-2);
; If model successfully comprehends (step3-1) it receives reward(1), otherwise (step3-2) it receives punishments(-1)
; Then, the model proceeds to the picture description task, parsing in the target picture from visual buffer (step1-2)
; Two syntactic structures compete (step2-1)(step2-2),
;       and the one w/ higher utility is chosen to produce constructions(step3-3)
; Lastly, the model speaks out the syntactic structure DO(step4-1), PO(step4-2),
;       to simulate the process of producing a full sentence
;
;;;####################################################################################################################



(clear-all)

;;; --------- PARAMETERS ---------
(define-model model2 "A pure RL model"

(sgp ;:seed(212 545)
     :v nil       ; output verbose
     :trace-detail low  ;high/medium/low
     ;:cst t     ; conflict set trace
     :er t      ; Enable randomness, how deterministically
     :esc t     ; Subsymbolic computations
     :ul t      ; Utility learning
     :ult t     ; Utility learning trace
     :ppm nil     ; Partial matching
     :egs 0.2     ; Production Randomness
     :alpha 0.1     ; Learning rate
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

;;; --------- DM ---------
(add-dm
   (state) (wait) (end) (yes) (no)
   (step1) (step2) (step3)  (step4)  (step5)  (step6)  (step7)
   (temp)
   (comprehend-sentence) (comprehend-picture)
   (wait-for-screen isa goal-state state wait)
   (wait-for-next-screen isa goal-state state next)
)


;;;---------------- COMPREHEND ----------------
(p step1-1
    "parse in the prime sentence, create a semantic representation in imaginal buffer"
    =goal>
        ISA goal-state
        state wait
        temp nil

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
    "create a semantic representation, and decide syntax DO"
    =goal>
        state step2
    ?imaginal>
        state free
    =imaginal>
        ISA semantics
        - syntax PO ; negation
==> 
    =imaginal>
    *goal>
        state step3
        temp DO
    )

(p step2-2
    "create a semantic representation, and decide syntax PO"
    =goal>
        state step2
    ?imaginal>
        state free
    =imaginal>
        ISA semantics
        - syntax DO
==> 
    =imaginal>
    *goal>
        state step3
        temp PO
    )

(p step3-1
    "find no error"
    =goal>
        state step3
    ?imaginal>
        state free
    =imaginal>
        ISA semantics
        syntax-corr yes
==> 
    *goal>
        state wait
    )

(p step3-2
    "find error"
    =goal>
        state step3
    ?imaginal>
        state free
    =imaginal>
        ISA semantics
        syntax-corr no
==> 
    *goal>
        state wait
    )

(p step3-3
    "produce"
    =goal>
        state step3
        temp =result
    ?imaginal>
        state free
    =imaginal>
        ISA semantics
        syntax nil
        syntax-corr nil
==>
    =imaginal>
    *goal>
        state step4

    *imaginal>
        syntax =result
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
        state step2

    +imaginal>
        ISA semantics
        agent =agent
        patient =patient
        action =action
    ;!output! ("in step 1-2 comprehend picture")
     )

(p step4-1
    "apply syntax DO"
    =goal>
        ISA goal-state
        state step4

    ?imaginal>
        state free
        buffer full

    =imaginal>
        ISA semantics
        syntax DO
        agent =agent
        patient =patient
        action =action
    ?vocal>
        state free
==> 
    *goal>
        state end

    +vocal>
        cmd speak
        string "DO"
    )

(p step4-2
    "apply syntax PO"
    =goal>
        ISA goal-state
        state step4

    ?imaginal>
        state free
        buffer full

    =imaginal>
        ISA semantics
        syntax PO
        agent =agent
        patient =patient
        action =action

    ?vocal>
        state free
==> 
    *goal>
        state end
    +vocal>
        cmd speak
        string "PO"
    )

(p step5
    "successfully produce a sentence"
    =goal>
        state end
==>
    -goal>
)
;------------ reward ------------
  ;(spp step3-1 :reward 1)
  ;(spp step3-2 :reward -1)

)
