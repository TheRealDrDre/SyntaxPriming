;;; Test demo


(p step1
   =goal>
     isa sentence-verification
     agent nil
     object nil
     action nil

   =visual>
     isa sentence
     noun1 =X
     noun2 =Y
     verb =Z
     
==>
   *goal>
     action =Z

   +retrieval>
     isa syntactic-structure  
)


(p step2-active
   =goal>
     isa sentence-verification
     agent nil
     object nil
   - action nil

   =visual>
     isa sentence
     noun1 =X
     noun2 =Y
     verb =Z

   =retrieval>
     isa syntactic-structure
     voice active
==>
   *goal>
     agent =X
     object =Y
  )

(p step2-passive
   =goal>
     isa sentence-verification
     agent nil
     object nil
   - action nil

   =visual>
     isa sentence
     noun1 =X
     noun2 =Y
     verb =Z

   =retrieval>
     isa syntactic-structure
     voice passive
==>
   *goal>
     agent =Y
     object =X
)
