# ASP: Cognitive Models of Syntactic Priming

This repository contains three different cognitive models that perform the Syntactic Priming experiment developed by Yuxue C. Yang, and Dr. Andrea Stocco

### Overview

Syntactic priming (SP) is the effect by which, in a dialogue, the current speaker tends to re-use the syntactic constructs of the previous speakers. SP has been used as a window into the nature of syntactic representations within and across languages. Because of its importance, it is crucial to understand the mechanisms behind it. Currently, two competing theories exist. According to the transient activation account, SP is driven by the re-activation of declarative memory structures that encode structures. According to the error-based implicit learning account, SP is driven by prediction errors while processing sentences. By integrating both transient activation and associative learning, Reitter et al.’s hybrid model (2011) assumes that SP is achieved by both mechanisms, and predicts a priming enhancement for rare or unusual constructions. Finally, a recently proposed account, the reinforcement learning account, claims that SP is driven by the successful application of procedural knowledge will be reversed when the prime sentence includes grammatical errors. These theories make different assumptions about the representation of syntactic rules (declarative vs. procedural) and the nature of the mechanism that drives priming (frequency and repetition, attention, and feedback signals, respectively). To distinguish between these theories, they were all implemented as computational models in the ACT-R cognitive architecture, and their specific predictions were examined through grid-search computer simulations. 

## Common structure of the models

All models are designed to have a similar structure and use comparable
representations. Specifically, all models used special chunks to
represent a the contents of a _picture_, the representation of a
_sentence_, and the _sematic representation_ of either a picture of a
sentence.

During the sentence verification trials (i.e., the prime trials), the
models first read a sentence, then generate a syntactic
representation, and finally verify the representation against the
picture.

During the sentence description trials (i.e., the target trials), the
models first observe a picture, then create a semantic representation,
and finally produce an active or passive sentence that represents the
internal semantic representation.


## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

Run actr environment before run the model. See http://act-r.psy.cmu.edu/

## Contribution

Syntactic Priming (SP) is an important linguistic phenomenon which helps to understand the mechanisms of syntactic representations. Our study firstly focused on the effect of ungrammatical constructions on SP. Moreover, based on three main accounts of SP, Activation account, Associative learning account, and Reinforcement Learning account, we implemented computational models in ACT-R. Our results contribute in many ways to the growing body of research on the computations underlying language processing.


## Authors

* Yuxue Cher Yang 
* Advisor: Andrea Stocco
* Undergraduate RA: Ann Marie Karmol

## Acknowledgments

This research was made possible by a Top Scholar award from the University of Washington to YCY, and by a grant from the Office of Naval Research (ONRBAA13-003) to AS.


