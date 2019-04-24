;;; -------------------------------------------------------------- ;;;
;;; Model 1 for SP: Reitter model
;;; -------------------------------------------------------------- ;;;
;;; Simulates SP as an effect of declarative memory usage. Follows
;;; the ideas of Reitter et al.
;;; -------------------------------------------------------------- ;;;
;;; Notes:
;;; The model should do something like
;;; 1. Develop a semantic representation (agent verb object)
;;; 2. Use a syntactic structure to produce a sentence noun1-verb-noun2
;;;
;;; * A sentence should have the following structure noun1-verb-noun2 (voice)
;;; * When struct is active, the sentence is created as agent-verb-object-actuve
;;; * When struct is passive, the sentence is created as oject-verb-agent-passive.
;;;
;;; Similarly, when reading a sentence, the sentence is read as noun1-verb-noun2.
;;; Then, a structure is retrieved depending on the 'voice' marker.
;;; If structure = active, the interpretation is produced as
;;;
;;;    agent/noun1 - verb - object/noun2
;;;
;;; If structure = passive, the interpretation is produced as
;;;
;;;    agent/noun2 - verb - object/noun1
;;;
;;;
;;; So the process is picture -> semantics -> sentence for production,
;;; and sentence -> semantics -> picture for verification.
;;; Problem: How do handle semantics and sentence in two different buffers?  


(clear-all)

(define-model declarative-sp-reitter

(sgp :er t  ; Enable randomness
     :esc t ; subsymbolic computations
     )
  
(chunk-type sentence
            string
            noun1
            verb
            noun2
            voice
            syntax-correct
            semantics-correct)
  
(chunk-type syntactic-structure
            voice
            language
            name)
  
(chunk-type picture
            kind
            agent
            object
            verb)

(chunk-type semantics
            agent
            object
            verb)

(chunk-type task
            goal
            agent
            verb
            object
            state
            done)


;;; Example representation of "the nun chases the robber"
  
(add-dm (nun) (chase) (robber) (active) (passive) (yes)
        (no) (speech-production) (sentence-comprehension)
        (verify-sentence-picture)
        (english) (drawing)
        (sentence1 isa sentence
                   string "the nun chases the robber"
                   noun1 nun
                   verb chase
                   noun2 robber
                   voice active
                   syntax-correct yes
                   semantics-correct yes)
        (picture1 isa picture
                  kind drawing
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
        (comprehend-goal isa task
                     goal sentence-comprehension
                     done no)
        (verify-goal isa task
                     goal verify-sentence-picture
                     done no)
        )

;; Sentence Comprehension and Verification
;;; picture -> put in goal buffer
;;; sentence -> put in img buffer 

(p interpret-prime-picture
   "Transforms a picture into a semantic representation"
   =goal>
     isa task
     goal sentence-comprehension
     done no
     agent nil

   =visual>
     isa picture
     agent =AGENT
     object =OBJECT
     verb =VERB

   ?goal>
     state free

==>
   *goal>
     agent =AGENT
     verb =VERB
     object =OBJECT 
)

(p start-verification
   "Transforms a picture into a semantic representation"
   =goal>
     isa task
     goal sentence-comprehension
     agent =AGENT
     verb =VERB
     object =OBJECT 
     done no

   ?goal>
     state free

   ?imaginal>
     state free
     buffer empty

==>
   +imaginal>
     isa semantics
     agent =AGENT
     verb =VERB
     object =OBJECT 

   =goal>
     isa task
     goal verify-sentence-picture
)


(p apply-correct-verification
   =goal>
     isa task
      goal verify-sentence-picture
      done no

   =imaginal>
     isa sentence
      semantics-correct yes

   ?imaginal>
     state free
   
   ?retrieval>
     state free
     buffer full

   =retrieval>
     isa syntactic-structure
     voice active
==>  
   *imaginal>
    isa sentence
     voice active
     semantics-correct yes
)


(p speak-correct-match
   "After applying it, you are done"
   =imaginal>
     isa sentence
     voice active
     semantics-correct yes
     
   =goal>
     done no

   ?vocal>
     state free
==>
     
   *goal>
     done yes

   +vocal>
     isa speak
     cmd speak
     string "yes"
)



;;; TODO: other conditions
;(p retrieve-active-semantic-incorrect)
;(p retrieve-passive-semantic-correct)
;(p retrieve-passive-semantic-incorrect)

;(p apply-correct-verification)
;(p speak-incorrect-match)

;; Production

(p interpret-picture
   "Transforms a picture into a semantic representation"
   =goal>
     isa task
     goal speech-production
     done no
     agent nil

   =visual>
     isa picture
     agent =AGENT
     object =OBJECT
     verb =VERB

   ?goal>
     state free

==>
   *goal>
     agent =AGENT
     verb =VERB
     object =OBJECT 
)

(p start-speech-production
   "Prepares imaginal buffer and loads agent, oject, and verb in WM"
   =goal>
     isa task
     goal speech-production
     done no
     verb =VERB
   
   ?imaginal>
     state free
     buffer empty
 ==>

   +imaginal>
     isa sentence
     verb =VERB
)
     
(p retrieve-syntactic-structure
   "Decides which structure to apply by retrieving it from memory"
   =goal>
     isa task
     goal speech-production
     done no

   =imaginal>
     isa sentence
     verb =VERB
     voice nil

   ?imaginal>
     state free
   
   ?retrieval>
     state free
     buffer empty
==>
   =imaginal>

   +retrieval>
     isa syntactic-structure
     language english
)

(p apply-syntax-active
   "If 'active' structure is retrieved, applies the S-V-O structure"

   =goal>
     isa task
     goal speech-production
     agent =AGENT
     object =OBJECT
     done no
   
   ?retrieval>
     state free
     buffer full

   =retrieval>
     isa syntactic-structure
     voice active

   =imaginal>
     isa sentence
     voice nil

   ?imaginal>
     state free  
==>  
   *imaginal>
     isa sentence
     noun1 =AGENT
     noun2 =OBJECT
     voice active
)


(p apply-syntax-passive
   "If 'passive' structure is retrieved, applies the O-V-S structure"
   =goal>
     isa task
     goal speech-production
     agent =AGENT
     object =OBJECT
     done no
   
   ?retrieval>
     state free
     buffer full

   =retrieval>
     isa syntactic-structure
     voice passive

   =imaginal>
     isa sentence
     voice nil

   ?imaginal>
     state free  
==>  
   *imaginal>
     isa sentence
     noun1 =OBJECT
     noun2 =AGENT
     voice active
)



;;; Produce a sentence
;;; For now, it simply says "active" or "passive", which makes it easy
;;; to keep track.

(p speak-active-sentence
   "After applying it, you are done"
   =imaginal>
     isa sentence
     noun1 =X
     noun2 =Y
     voice active
     
   =goal>
     done no

   ?vocal>
     state free

==>
     
   *goal>
     done yes

   +vocal>
     isa speak
     cmd speak
     string "active"
)


(p speak-passive-sentence
   "After applying it, you are done"
   =imaginal>
     isa sentence
     noun1 =X
     noun2 =Y
     voice passive
     
   =goal>
     done no

   ?vocal>
     state free

==>
     
   *goal>
     done yes

   +vocal>
     isa speak
     cmd speak
     string "active"
)


; see prime picture
(goal-focus comprehend-goal)
;(set-buffer-chunk 'visual 'picture1)
(set-buffer-chunk 'visual 'picture1)


; read prime sentence


; see target picture
;(goal-focus speech-goal)
;(set-buffer-chunk 'visual 'picture1)


)
