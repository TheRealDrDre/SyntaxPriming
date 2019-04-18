;;; -------------------------------------------------------------- ;;;
;;; Model 1 for SP: Reitter model
;;; -------------------------------------------------------------- ;;;
;;; Simulates SP as an effect of declarative memory usage. Follows
;;; the ideas of Reitter et al.
;;; -------------------------------------------------------------- ;;;

(clear-all)

(define-model declarative-sp

(sgp :er t ; Enable randomness
     )
  
(chunk-type sentence
            string
            agent
            object
            verb
            voice
            syntax-correct
            semantics-correct)
  
(chunk-type syntactic-structure
            voice
            language
            name)
  
(chunk-type picture
            agent
            object
            verb)

(chunk-type task
            goal
            done)


;;; Example representation of "the nun chases the robber"
  
(add-dm (nun) (chase) (robber) (active) (passive) (yes)
        (no) (speech-production) (sentence-comprehension)
        (english)
        (sentence1 isa sentence
                   string "the nun chases the robber"
                   agent nun
                   verb chase
                   object robber
                   voice active
                   syntax-correct yes
                   semantics-correct yes)
        (picture1 isa picture
                  agent nun
                  object robber
                  verb chase)
        (active-voice isa syntactic-structure
                      voice active
                      language english
                      name active)
        (passive-voice isa syntactic-structure
                       voice passive
                       language english
                       name passive)
        (speech-goal isa task
                     goal speech-production
                     done no)
        )

;; Comprehension

(p parse-sentence
   =goal>
     isa task
     goal sentence-comprehension
==>
)

;; Production

(p start-speech-production
   "Prepares imaginal buffer and loads agent, oject, and verb in WM"
   =goal>
     isa task
     goal speech-production
     done no

   =visual>
     isa picture
     agent =AGENT
     object =OBJECT
     verb =VERB
   
   ?imaginal>
     state free
     buffer empty
 ==>
   =visual>  
   +imaginal>
     isa sentence
     agent =AGENT
     object =OBJECT
     verb =VERB
     syntax-correct yes
     semantics-correct yes
)
     
(p retrieve-syntactic-structure
   "Decides which structure to apply by retrieving it from memory"
   =goal>
     isa task
     goal speech-production
     done no

   =visual>
     isa picture
     agent =AGENT
     object =OBJECT
     verb =VERB

   =imaginal>
     isa sentence
     agent =AGENT
     object =OBJECT
     verb =VERB
     syntax-correct yes
     semantics-correct yes
     voice nil

   ?imaginal>
     state free
   
   ?retrieval>
     state free
     buffer empty
==>
   =goal>
   =imaginal>
   =visual>
   +retrieval>
     isa syntactic-structure
     language english
   - voice nil
)

(p produce-sentence
   "After retrieving a syntactic structures, you apply it"
   ?retrieval>
     state free
     buffer full

   =retrieval>
     isa syntactic-structure
     voice =VOICE

   =imaginal>
     isa sentence
     voice nil

   ?imaginal>
     state free  
==>  
   *imaginal>
     isa sentence
     voice =VOICE
)

(p done-production
   "After applying it, you are done"
   =imaginal>
     isa sentence
     agent =AGENT
     object =OBJECT
     verb =VERB
     syntax-correct yes
     semantics-correct yes
   - voice nil
     
   =goal>
     done no
==>
   *goal>
     done yes
)

(goal-focus speech-goal)
(set-buffer-chunk 'visual 'sentence1)

)
