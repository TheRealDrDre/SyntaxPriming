(clear-all)

(define-model pure-procedural

(sgp :er t  ; Enable randomness
     :esc t ; Subsymbolic computations
     :ul t  ; Utility learning
     :ppm 1 ; Partial matching
     :egs 1.5
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
            action
            patient
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
        (wait)
        (undecided) (active) (passive)
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
   =visual>   
   +goal>
     isa task
     goal sentence-comprehension
     done no)


;;; Comprehend

(p start-comprehension-plan
   =goal>
     isa task
     goal sentence-comprehension
     done no

   =visual>
     isa sentence
     noun1 =N1
     verb  =V
     noun2 =N2
     voice =VOICE
     
   ?goal>
     state free

   ?imaginal>
     state free
     buffer empty
==>
   =visual>     
   +imaginal>
     isa sentence-plan
     kind sentence-plan
     noun1 =N1
     verb  =V
     noun2 =N2
     voice =VOICE
     completed no
)

(p prepare-semantics
   =goal>
     isa task
     goal sentence-comprehension
     done no

   ?imaginal>
     state free

   =imaginal>
     noun1 =N1
     verb  =V
     noun2 =N2
     completed yes

==>
  *goal>
    agent   =N1
    action  =V
    patient =N2
    done yes
)

;;; Done!

(p sentence-comprehension-no-error
   =goal>
     isa task
     goal sentence-comprehension
   - agent nil
   - action nil
   - patient nil

   ?goal>
     state free

   =visual>
     kind sentence
     syntax-correct yes
==>
   +goal>
     isa task
     goal wait
   !stop!
)

(p sentence-comprehension-error
   =goal>
     isa task
     goal sentence-comprehension
   - agent nil
   - action nil
   - patient nil

   ?goal>
     state free

   =visual>
     kind sentence
     syntax-correct no
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

(p start-production-plan
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
     verb  =ACT
     noun2 =N2
     voice undecided
     completed no
)

(p apply-active-structure
   =imaginal>
     kind sentence-plan
     voice active
     completed no

   ?imaginal>
     state free  
==>
   *imaginal>
     voice active
     completed yes
)


(p apply-passive-structure
   =imaginal>
     kind sentence-plan
     voice passive
     completed no
     noun1 =N1
     noun2 =N2

   ?imaginal>
     state free  
==>
   *imaginal>
     voice passive
     completed yes
     noun1 =N2
     noun2 =N1
)


(p produce
   =goal>
     isa task
     goal sentence-production
     done no

   =imaginal>
     kind sentence-plan
     completed yes
     
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

(spp (sentence-comprehension-no-error :reward 10)
     (sentence-comprehension-error :reward -10))

(set-similarities (active undecided 0.5) (passive undecided 0.5))
(goal-focus wait-for-screen)
)
