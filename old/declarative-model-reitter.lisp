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
;;; * When struct is active, the sentence is created as agent-verb-object-active
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
            kind 
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
            name) ;??
  
(chunk-type picture
            kind ;?? no diff between picture and semantics
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
  
(add-dm (nun) 
        (chase) 
        (robber) 
        (active) 
        (passive) 
        (yes)
        (no) 
        (speech-production) 
        (sentence-comprehension)
        (verify-sentence-picture)
        (english) 
        (drawing)
        ;;; Sentence and Picture Content
        (sentence1 ISA sentence
                   string "the nun chases the robber"
                   noun1 nun
                   verb chase
                   noun2 robber
                   voice active
                   syntax-correct yes
                   semantics-correct yes)
        (picture1 ISA picture
                  kind drawing ;??
                  agent nun
                  verb chase
                  object robber)
        
        ;;; Syn-structure
        (active-voice ISA syntactic-structure
                      voice active
                      language english
                      name active) ;??
        (passive-voice ISA syntactic-structure
                       voice passive
                       language english
                       name passive) ;??
        ;;; GOAL 
        (speech-goal ISA task
                     goal speech-production
                     done no)
        (comprehend-goal ISA task
                     goal sentence-comprehension
                     done no)
        (verify-goal ISA task
                     goal verify-sentence-picture
                     done no)
        )

;; Sentence Comprehension and Verification
;;; picture -> put in goal buffer
;;; sentence -> put in img buffer 

    ;;; @function: This production allows the model to hold the content of the prime picture. 
    ;;; @todo: The goal buffer is initialized to 'sentence-comprehension' task. The model first 
        ;;; looks at visual buffer (picture), and modifies the goal buffer, copying the chunk 
        ;;; (slots-values) in visual buffer TO goal buffer. 
    ;;; @return: goal buffer has a 
        ;;; chunk-type: task, 
        ;;; goal: sentence-comprehension, 
        ;;; done: no
        ;;; agent: AGENT (pic)
        ;;; object =OBJECT (pic)
        ;;; verb =VERB (pic)
(p interpret-prime-picture
   "Holding picture in wm"
   =goal>
     ISA task
     goal sentence-comprehension
     done no
     agent nil ;; why not verb nil and object nil?
   
   =visual>
     ISA picture
     agent =AGENT
     object =OBJECT
     verb =VERB

   ?goal>
     state free ;; not performing any actions
==>   
   ;;; copy chunks from visual buffer to goal buffer
   *goal>
   ;;; can I mofify the chunk type? what chuknk type in goal buffer -- ISA task
     agent =AGENT
     verb =VERB
     object =OBJECT 
       ; some impliict attributes
       ; ISA task
       ; goal sentence-comprehension
       ; done no
       ; state 
   !output! (=VERB)
)
    
    ;;; This production allows the model to convert the semantic representation of the prime picture and store it into imaginal buffer
(p start-verification
   "Transforms a picture into a semantic representation"
   =goal>
     ISA task
     goal sentence-comprehension ;; inehrit the goal from "interpret-prime-picture"
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
   ;;; parse in the prime sentence and hold in imaginal buffer
   +imaginal>
     ISA semantics
     agent =AGENT
     verb =VERB
     object =OBJECT 
    
    ;;; modify goal buffer and change to a new chunk
   =goal>
     isa task
     goal verify-sentence-picture
   
   !output! (=AGENT)
)

    ;;; This production allows the model to retrieve ACTIVE syntax if the picture-sentence(Active) is a match, and there is no grammar error
(p correct-verification
   "If picture and sentence match, retrieve syntactic structure"
   =goal>
       ISA task
       goal verify-sentence-picture
       done no

   =visual> ;;; look at screen and parse in sentence
     ISA sentence
      noun1 =X ; assign noun1 to variable X
      noun2 =Y ; assign noun2 to variable Y
      verb =VERB ; assign verb to variable VERB
  
   =imaginal> ;;; inherit from start-verification production
     ISA semantics
      agent =X
      object =Y 
      verb =VERB

   ?imaginal>
     state free
   
   ?retrieval>
     state free
     buffer nil

==>  
   ;;; Modify imaginal buffer (semantics -> sentence) 
   *imaginal>
    ISA sentence
     voice active
     semantics-correct yes
       ;other attributes are nil

   ;;; Request a retrieval from dm, and put in retrival buffer
   +retrieval>
    ISA syntactic-structure
     voice active
     language english
)
    
    ;;; This production allows the model to 

(p speak-correct-match
   "After applying it, you are done"
   =imaginal> ;;; inherit from correct-verification production
     ISA sentence
     voice active
     semantics-correct yes
     
   =goal>
     done no ;;;ISA task, verify-sentence-picture

   ?vocal>
     state free

   ?retrieval> ;;;  ISA syntactic-structure, voice active, language english
     state free
     buffer full
   
==>
   
   *goal>
     done yes ;;; should I change to speech-production???

   +vocal>
     ISA speak
     cmd speak
     string "yes"

   -retrieval> ;;; clear retrieval buffer
    
)

;;; TODO: other conditions
;;; TODO: pay attention to visual buffer and production task
;(p retrieve-active-semantic-incorrect)
;(p retrieve-passive-semantic-correct)
;(p retrieve-passive-semantic-incorrect)

;(p apply-correct-verification)
;(p speak-incorrect-match)

;; Production

    ;;; This production is allows the model to interpret target picture and transform picture content into a goal buffer
(p interpret-picture
   "Transforms a picture into a semantic representation"
   =goal>
     ISA task
     goal speech-production ;;; when does speech-production is initiated 
     done no
     agent nil

   =visual>
     ISA picture
     agent =AGENT
     object =OBJECT
     verb =VERB

   ?goal>
     state free

==>
   ;;; put picture info into goal buffer, type is still a task
   *goal>
     agent =AGENT
     verb =VERB
     object =OBJECT 
)

    ;;;This production allows the model to produce a sentence. It loads agent, object and verb from goal buffer and put in imaginal buffer
(p start-speech-production
   "Prepares imaginal buffer and loads agent, oject, and verb in WM"
   =goal>
     ISA task
     goal speech-production
     done no
     verb =VERB
   
   ?imaginal>
     state free
     buffer empty
 ==>

   +imaginal>
     ISA sentence
     verb =VERB
)
     ;;; retrieve the most recent memory about syntactic structure
(p retrieve-syntactic-structure
   "Decides which structure to apply by retrieving it from memory"
   =goal>
     isa task
     goal speech-production
     done no

   =imaginal>
     ISA sentence
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
     ISA syntactic-structure
     voice active

   =imaginal>
     ISA sentence
     voice nil

   ?imaginal>
     state free  
==>  
   *imaginal>
     ISA sentence
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
     voice active ;;; passive???
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
(set-buffer-chunk 'visual 'picture1)


; read prime sentence


; see target picture
;(goal-focus speech-goal)
;(set-buffer-chunk 'visual 'picture1)


)
