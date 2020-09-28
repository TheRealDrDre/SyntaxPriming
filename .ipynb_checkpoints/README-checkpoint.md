# Models of Syntactic Priming

This repository contains alternative models that perform the Syntactic
Priming experiment developed by Yuxue Cher Yang.

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
