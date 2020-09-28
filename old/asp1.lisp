(clear-all)

(define-model asp1

(sgp :er t  ; Enable randomness
     :esc t ; Subsymbolic computations 
     :bll .1 ; Base-level learning (for memory)
     :ul t  ; Utility learning
     ;:ppm 1 ; Partial matching
     :egs 1.5 ;Noises
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
            name) 
  
(chunk-type picture
            kind 
            agent
            patient
            action)

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

    (add-dm (nun) 
        (chase) 
        (robber)
            (semantics-correct)(syntax-correct)
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
;;         (sentence1 ISA sentence
;;                    string "the nun chases the robber"
;;                    noun1 nun
;;                    verb chase
;;                    noun2 robber
;;                    voice active
;;                    syntax-correct yes
;;                    semantics-correct yes)
;;         (picture1 ISA picture
;;                   kind drawing ;??
;;                   agent nun
;;                   action chase
;;                   patient robber)
;;         (picture2 ISA picture
;;                   kind drawing ;??
;;                   agent robber
;;                   action chase
;;                   patient nun)
        
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

    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Verification ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;; Step1. Looking at visual buffer and copy chunk(picture) in visual buffer to goal buffer
(p interpret-prime-picture
   "Encoding prime picture"
   =goal>
     ISA task
     goal sentence-comprehension
     done no
     agent nil 
   
   =visual>
     ISA picture
     agent =AGENT
     patient =OBJECT
     action =VERB

   ?goal>
     state free 
==>   
   *goal>
     agent =AGENT
     verb =VERB
     object =OBJECT 
   !output! ("finish step 1")
)
    ;;; Step2: checking goal buffer, and create a semantic representation of the picture, and update goal buffer to "verify-sentence-picture"
(p start-verification
   "Transforms a picture into a semantic representation"
   =goal>
     ISA task
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
   ;;; create a semantic representation of the prime picture
   +imaginal>
     ISA semantics
     agent =AGENT
     verb =VERB
     object =OBJECT 
    
   =goal>
     goal verify-sentence-picture ; go to next goal: verify-sentence-picture

   !output! ("finish step 2")     
)

    ;;; PURE-DECLARATIVE
    ;;; Step3.1: When prime sentence is AC, and picture-sentence is matching, Retrieving ACTIVE.
    ;;; modify new chunk in imagial buffer
(p active-correct-match
   "If picture and sentence match, retrieve syntactic structure"
   =goal>
       ISA task
       goal verify-sentence-picture
       done no
  
   =imaginal> ;;; inherit from start-verification production
     ISA semantics
      agent =X
      object =Y 
      verb =VERB
   
   =visual>
    ISA sentence
    noun1 =X
    verb =VERB
    noun2 =Y
    voice active
;;     syntax-correct yes ; THIS line suggests the model predicts no-effect of syntactic correctness
       
   ?imaginal>
     state free
   
   ?retrieval>
     state free
     buffer empty

==>  
   ;;; Modify imaginal buffer (semantics -> sentence) 
   +imaginal>
    ISA sentence
     voice active
     semantics-correct yes
;;syntax-correct yes  ;other attributes are nil

   ;;; Request a retrieval from dm, and put in retrival buffer
   +retrieval>
    ISA syntactic-structure
     voice active
     language english
   
   !output! ("finish step 3: match")  
)
    
    ;;; Step3.2: When the prime sentence is AC, and picture-sentence is matching, Retrieving ACTIVE.
    ;;; modify new chunk in imagial buffer, 
(p passive-correct-match
   "If picture and sentence match, retrieve syntactic structure"
   =goal>
       ISA task
       goal verify-sentence-picture
       done no
  
   =imaginal> ;;; inherit from start-verification production
     ISA semantics
      agent =X
      object =Y 
      verb =VERB
   
   =visual>
    ISA sentence
    noun1 =X
    verb =VERB
    noun2 =Y
    voice passive      
    ; syntax-correct yes 

   ?imaginal>
     state free
   
   ?retrieval>
     state free
     buffer empty
==>  
   ;;; Modify imaginal buffer (semantics -> sentence) 
   =imaginal>
    ISA sentence
     voice passive
     semantics-correct yes
    ;;syntax-correct yes
   
   ;;; Request a retrieval from dm, and put in retrival buffer
   +retrieval>
    ISA syntactic-structure
     voice passive
     language english
   !output! ("finish step 3: PC-match")  
)
    
    
    ;;; >> Step 3.3 
    ;(p active-incorrect-match )
    ;;; >> Step 3.4
    ;(p passive-incorrect-match )
    
    ;;; Step 4.1: When picture-sentence is matching, speak out "yes"
(p speak-match
   "After applying it, you are done"
   =imaginal> 
     ISA sentence
     semantics-correct yes
     
   =goal>
       goal verify-sentence-picture
       done no 

   ?vocal>
     state free

   ?retrieval> 
     state free
     buffer full
   
   ?visual>
    buffer empty
   
==>
   +goal>
       goal speech-production
       done no

   +vocal>
     ISA speak
     cmd speak
     string "yes"

   -retrieval> ; clear retrieval buffer
   
   !output! ("finish step 4: speak match!")  
)
    
    ;;; Step 4.2: When picture-sentence is not matching, speak out "no"
    (p speak-notmatch
   "After applying it, you are done"
   =imaginal> 
     ISA sentence
     semantics-correct no
     
   =goal>
     done no 

   ?vocal>
     state free

   ?retrieval> 
     state free
     buffer full
   
   ?visual>
    buffer empty
   
==>
   
   +goal>
       goal speech-production 
       done no
   +vocal>
     ISA speak
     cmd speak
     string "no"

   -retrieval> ; clear retrieval buffer
   
   !output! ("finish step 4: speak NOT match!")  
)
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Production  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ;;; Step 5: checking goal buffer, new goal: speech-production. 
    ;;; Encoding the target picture and transform picture content into a goal buffer

    (p interpret-target-picture
   "Transforms a picture into a semantic representation"
   =goal>
     ISA task
     goal speech-production 
     done no

   =visual>
     ISA picture
     agent =AGENT
     patient =OBJECT
     action =VERB

   ?goal>
     state free

==>
   *goal>
     agent =AGENT
     verb =VERB
     object =OBJECT 
   !output! ("finish step 5")
)
    
    ;;;Step 6: This production allows the model to produce a sentence. 
    ;;; It loads agent, object and verb from goal buffer and put in imaginal buffer
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
   
   !output! ("finish step 6")
)
    
    
    ;;; Step 7: retrieve the most recent memory about syntactic structure
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
   
   !output! ("finish step 7")
)
    
    ;;; Step 8: apply the retrieved syntactic structure 
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
       
    !output! ("finish step 8.1: apply active")
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
     voice passive ;;; passive???

    !output! ("finish step 8.2 apply passive")
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
   !output! ("finish step 9.1 active")
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
     string "passive"
   !output! ("finish step 9.2 passive")
)

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    (spp 
     (active-correct-match :reward 10)
     (passive-correct-match :reward 10)
     ;(active-incorrect-match :reward -10)
     ;(passive-incorrect-match :reward -10)
     )
    
    ;(goal-focus comprehend-goal)
    ;(set-buffer-chunk 'visual' picture1)
    
    ;(goal-focus speech-goal)
    ;(set-buffer-chunk 'visual' picture2)
    )