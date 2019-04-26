# SP Device

# General structure:
# 1. Present a sentence to visual buffer
# 2. Run model until it stops
# 3. Present a picture to visual buffer
# 4. Run model until it stops
# 5. Record structure used.


import actr

class Sentence():
    """A SP experiment stimulus"""
    def __init__(self, condition=None, verb=None, sentence=None):
        if condition is not None:
            self.condition = condition
        if verb is not None:
            self.verb = verb
        if sentence is not None:
            self.sentence = sentence
            tokens = sentence.split()
            self.noun1 = tokens[1].strip()
            self.noun2 = tokens[-1].strip().strip(".")

    @property
    def chunk_definition(self):
        voice = 'active'
        syntax_correct = 'yes'
    
        if self.condition.startswith('P'):
            voice = 'passive'

        if self.condition.endswith('I'):
            syntax_correct = 'no'

        return ['isa', 'sentence',
                'kind', 'sentence',
                'noun1', self.noun1,
                'verb', self.verb,
                'noun2', self.noun2,
                'voice', voice,
                'syntax-correct', syntax_correct,
                'string', "'%s'" % self.sentence]

    
    def __str__(self):
        return "<[%s] %s, %s, %s ('%s')>" % (self.condition,
                                             self.noun1,
                                             self.verb,
                                             self.noun2,
                                             self.sentence)

    def __repr__(self):
        return self.__str__()
            
def import_sentences(fle):
    """Parses a log and extracts data"""
    f = open(fle)
    lines = f.readlines()[1:]
    N = len(lines)
    tokens = [x.split(",") for x in lines]
    selected = [[x[5], x[4]] for x in tokens]
    sentences = [x[7] for x in tokens]
    tokenized = [sentence.split() for sentence in sentences]
    nouns = [[tokens[1], tokens[-1]] for tokens in tokenized]
    final = [selected[j] + nouns[j] + [sentences[j]] for j in range(N)]
    # print(final)
    stimuli = [Sentence(selected[j][0], selected[j][1], sentences[j])
               for j in range(N)]
    return stimuli


class Picture():
    """A structure to hold a picture"""
    def __init__(self, agent="drbrown",
                 action="yell",
                 patient="martymcfly"):
        self.agent = agent
        self.patient = patient
        self.action = action

    
    @property
    def chunk_definition(self):
        """Transforms a picture into a chunk definition"""
        return ['isa', 'picture',
                'kind', 'picture', 
                'agent', self.agent,
                'action', self.action,
                'patient', self.patient]

    
    def __repr__(self):
        """Visual representation"""
        return "<{P} %s, %s, %s>" % (self.agent,
                                     self.action,
                                     self.patient)

    def __str__(self):
        return self.__repr__()

    
def import_pictures(fle):
    """Imports the pictures used in the study"""
    return [Picture() for j in range(36)]


def run_trial(sentence, picture):
    """A trial"""
    chunk_s = actr.define_chunks(sentence.chunk_definition)[0]
    actr.set_buffer_chunk('visual',
                          chunk_s)
    actr.run(time = 100)

    chunk_p = actr.define_chunks(picture.chunk_definition)[0]
    actr.schedule_set_buffer_chunk('visual',
                                   chunk_p,
                                   actr.mp_time() + 0.05)
    actr.run(time = 100)
    
