;;; Model 4: A Sequential Procedural RL model for DO/PO -
(clear-all)

;;; --------- PARAMETERS ---------
(define-model model4 "A sequential procedural model"

(sgp ;:seed (250 20)
     :v nil      ; output verbose
     :trace-detail low  ;high/medium/low
     :model-warnings nil
     :style-warnings nil
     :cst nil     ; conflict set trace
     :er t      ; Enable randomness, how deterministically
     :esc t     ; Subsymbolic computations
     :ul t      ; Utility learning
     :ult nil   ; Utility learning trace
     :egs 1.5     ; Production Randomness
     :alpha 0.2     ; Learning rate
     :ppm 3     ; Partial matching
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
    syntax-corr
    decide-syntax)
(chunk-type picture
    agent
    patient
    action)

;;; --------- DM ---------
(add-dm
   (state) (wait) (next) (end) (yes) (no)
   (step1) (step2) (step3)  (step4)  (step5)  (step6)  (step7) (decide-syntax)
   (DO) (PO) (undecided)
   (comprehend-sentence) (comprehend-picture)
   (wait-for-screen isa goal-state state wait)
   (wait-for-next-screen isa goal-state state next)
)

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
    ;=visual>

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
    "no error, decide syntax based on the prime"
    =goal>
        state step2

    ?imaginal>
        state free

    =imaginal>
        ISA semantics
        syntax-corr yes
        syntax =syn
        decide-syntax nil
==>
    ;*goal>
    ;    state next
    
    *imaginal>
        decide-syntax =syn
    !output! ("step2-1: decide-syntax ")
    !output! (=syn)
    )

(p step2-2
    "find error, undecided"
    =goal>
        state step2

    ?imaginal>
        state free

    =imaginal>
        ISA semantics
        syntax-corr no
        - syntax nil
        decide-syntax nil
==>
    ;*goal>
    ;    state next

    *imaginal>
        decide-syntax undecided
    !output! ("decide-syntax: undecided")
    )


; (p step3-1
;     "decide to speak DO"
;     =goal>
;         state step3

;     ?imaginal>
;         state free

;     =imaginal>
;         ISA semantics
;         decide-syntax DO
; ==>
;     *goal>
;         state step3-3

;     *imaginal>
;         syntax DO
;     )

; (p step3-2
;     "decide to speak PO"
;     =goal>
;         state step3-3

;     ?imaginal>
;         state free

;     =imaginal>
;         ISA semantics
;         decide-syntax PO
; ==>
;     *goal>
;         state step3-3

;     *imaginal>
;         syntax PO
;     )


; (p step3
;     "prepare to produce"
;     =goal>
;         state step3

;     ?imaginal>
;         state free

;     =imaginal>
;         ISA semantics
;         - decide-syntax nil
;         - syntax nil 
; ==> 
;     *imaginal>
;         syntax nil
;         syntax-corr nil

;     *goal>
;         state next
;     )

;------------- PRODUCTION -------------
(p step1-2
    "parse in the target picture, create a semantic representation in imaginal buffer"

    =goal>
        ISA goal-state
        state next

    ?imaginal>
        state free

    =imaginal>
        ISA semantics

    =visual>
        ISA picture
        agent =agent
        patient =patient
        action =action
==>
    *goal>
        state step3

    *imaginal>
        agent =agent
        patient =patient
        action =action
    ;!output! ("in step 1-2 comprehend picture, syntax is undecided" )
     )

; ;;; two competing productions 3-1 and 3-2
(p step3-1
    "speak DO"
    =goal>
        state step3

    ?imaginal>
        state free

    =imaginal>
        ISA semantics
        decide-syntax DO

    ?vocal>
        state free

==>        
    *goal>
        state end
    
    +vocal>
        cmd speak
        string "DO"
    )

(p step3-2
    "speak PO"
    =goal>
        state step3

    ?imaginal>
        state free

    =imaginal>
        ISA semantics
        decide-syntax PO

    ?vocal>
        state free

==>        
    *goal>
        state end
    
    +vocal>
        cmd speak
        string "PO"
    )
;------------ reward ------------
(spp step2-1 :reward 1)
(spp step2-2 :reward -1)
; ------------ similarity ------------
(set-similarities (DO undecided -.5) (PO undecided -.5))
)
