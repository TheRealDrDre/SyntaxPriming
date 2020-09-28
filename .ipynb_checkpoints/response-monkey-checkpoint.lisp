(clear-all)

(define-model procedural-parser

(sgp :er t  ; Enable randomness
     :esc t ; Subsymbolic computations
     :ul t  ; Utility learning
     )
  
(chunk-type sentence
            kind
            string
            noun1
            verb
            noun2
            voice
            syntax-correct
            semantics-correct)
  
(chunk-type syntactic-structure
            kind
            voice
            language
            name)
  
(chunk-type picture
            kind
            agent
            action
            patient)

(chunk-type semantics
            kind
            agent
            object
            verb)

(chunk-type task
            kind
            goal
            agent
            verb
            object
            state
            done)

;;; Example representation of "the nun chases the robber"
  
(add-dm (nun) (chase) (robber) (active) (passive) (yes)
        (no) (sentence-production) (sentence-comprehension)
        (verify-sentence-picture)
        (english) (drawing)
        (sentence) (picture)
        (wait)
        (active-voice isa syntactic-structure
                      voice active
                      language english
                      name active)
        (passive-voice isa syntactic-structure
                       voice passive
                       language english
                       name passive)
        (wait-for-screen isa task
                         goal wait)
        )


;;; -------------------------------------------------------------- ;;;
;;; ACTIVE VS. PASSIVE SENTENCES
;;;

;(p choose-active-voice
;   ==>
;   )

;(p choose-passive-choice
;   ==>
;   )

;;; -------------------------------------------------------------- ;;;;
;;; SENTENCE COMPREHENSION
;;; 

(p start-sentence-comprehension
   =visual>
     kind sentence
   
   =goal>
     goal wait
==>
   -visual>   
   +goal>
     isa task
     goal sentence-comprehension
     done no)


;;; Comprehend

(p comprehend
   =goal>
     isa task
     goal sentence-comprehension
     done no

   ?goal>
     state free  
==>
   *goal>
     done yes
)


;;; Done!

(p stop-sentence-comprehension
   =goal>
     isa task
     goal sentence-comprehension
     done yes
     
   ?goal>
     state free  
==>
   +goal>
     isa task
     goal wait
   !stop!
)


;;; -------------------------------------------------------------- ;;;;
;;; SENTENCE PRODUCTION
;;;                                                               -;;;;

(p start-sentence-production
   =visual>
     kind picture
   
   =goal>
     goal wait

 ==>
   =visual>    
   +goal>
     isa task
     goal sentence-production
     done no)

;;; Produce

(p produce
   =goal>
     isa task
     goal sentence-production
     done no
     
   ?goal>
     state free  
==>     
   *goal>
     done yes
)


;;; Done!

(p stop-sentence-production
   =goal>
     isa task
     goal sentence-production
     done yes

   ?goal>
     state free
   
   ?vocal>
     state free  
==>
   +vocal>
     isa speak
     cmd speak
     string "active"
   -visual>
   +goal>
     isa task
     goal wait
     
;   !stop!  
)

(goal-focus wait-for-screen)
)
