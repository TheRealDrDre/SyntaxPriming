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

(chunk-type sentence-plan
            kind
            noun1
            verb
            noun2
            voice
            completed)


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

(add-dm (waitress) (monk) (ballerina)
        (swimmer) (doctor) (policeman)
        (artist) (sailor) (pirate)
        (professor) (nun) (chef)
        (boxer) (clown) 
        (soldier) (robber) (cowboy)

        (follow) (tickle) (kiss)
        (shot) (pull) (shoot)
        (scold) (push) (kick)
        (touch) ;(punch)
        (chase) (slap)

        (no) (yes)
        (sentence-production) (sentence-comprehension)
        (verify-sentence-picture)
        (english) (drawing)
        (sentence) (picture)
        (wait) (active) (passive)
        (sentence-plan)

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

(p start-sentence-plan
   =visual>
     kind picture
     agent =N1
     patient =N2
     action =ACT
   
   =goal>
     goal sentence-production
     done no

   ?imaginal>
     state free  
     buffer empty
==>
   +imaginal>
     isa sentence-plan
     kind sentence-plan
     noun1 =N1
     verb =ACT
     noun2 =N2
)

(p apply-active-structure
   =imaginal>
     kind sentence-plan
     voice nil

   ?imaginal>
     state free  
==>
   *imaginal>
     voice active
)


(p apply-passive-structure
   =imaginal>
     kind sentence-plan
     voice nil

   ?imaginal>
     state free  
==>
   *imaginal>
     voice passive
)


(p produce
   =goal>
     isa task
     goal sentence-production
     done no

   =imaginal>
     kind sentence-plan
   - voice nil
     
   ?goal>
     state free

   ?imaginal>
     state free  
==>
   =imaginal>   
   *goal>
     done yes
)


;;; Done!

(p say-active
   =goal>
     isa task
     goal sentence-production
     done yes

   =imaginal>
     voice active
   
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

(p say-passive
   =goal>
     isa task
     goal sentence-production
     done yes

   =imaginal>
     voice passive
   
   ?goal>
     state free
   
   ?vocal>
     state free  
==>
   +vocal>
     isa speak
     cmd speak
     string "passive"
   -visual>
   +goal>
     isa task
     goal wait
     
;   !stop!  
)

(goal-focus wait-for-screen)
)
