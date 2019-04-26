## ---------------------------------------------------------------- ##
## SYNTACTIC PRIMING MODEL MANAGEMENT AND INTERFACE
## ---------------------------------------------------------------- ##
## Usage:
##
##   import sp
##   s = sp.Simulation(n=25)
##   s.simulate()
##   s.data
## ---------------------------------------------------------------- ##

import actr
import os
import random

CONDITIONS =  ['AC', 'AI', 'PC', 'PI']

class SP_Object():
    """The root of all experiment objects"""
    CONDITIONS = ('AC', 'AI', 'PC', 'PI')
    pass

class Sentence(SP_Object):
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


class Picture(SP_Object):
    """A structure to hold a picture"""
    def __init__(self, agent="drbrown",
                 action="yell",
                 patient="martymcfly",
                 id = None):
        """Initializes a picture"""
        self.agent = agent
        self.patient = patient
        self.action = action
        self.id = id

    
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
        return "<{%s} %s, %s, %s>" % (self.id,
                                      self.agent,
                                      self.action,
                                      self.patient)

    def __str__(self):
        return self.__repr__()


class Trial(SP_Object):
    """Trial"""
    def __init__(self, condition, sentence, picture):
        self.condition = condition
        self.sentence = sentence
        self.picture = picture

    @property
    def condition(self):
        """Returns the condition"""
        return self._condition

    @condition.setter
    def condition(self, value):
        """Sets the condition (Active/Passive, Correct/Incorrect)"""
        if value.upper() in ['AC', 'AI', 'PC', 'PI']:
            self._condition = value

        voice = 'active'
        syntax_correct = 'yes'
    
        if self.condition.startswith('P'):
            voice = 'passive'

        if self.condition.endswith('I'):
            syntax_correct = 'no'

        self.voice = voice
        self.syntax_correct = 'no'
        

    def __str__(self):
        """A representation of the trial"""
        return "<[%s] S:%s, P:%s>" % (self.condition,
                                      self.sentence,
                                      self.picture)

    def __repr__(self):
        """A representation of the trial"""
        return self.__str__()

    
def load_trials(file="stimuli.txt"):
    """A trial"""
    f = open(file)
    lines = f.readlines()[1:]
    N = len(lines)
    tokenized = [x.split("\t") for x in lines]
    trials = []
    for tokens in tokenized:
        trial_type = tokens[3]

        t_verb = tokens[0]
        t_image_ID = tokens[2]
        t_image_agent = tokens[12]
        t_image_object = tokens[13]

        pic = Picture(agent = t_image_agent,
                      patient = t_image_object,
                      action = t_verb,
                      id = t_image_ID)

        p_noun1 = tokens[10]
        p_noun2 = tokens[11]
        p_sentence = tokens[4]
        
        sen = Sentence(condition = trial_type,
                       verb = t_verb,
                       sentence = p_sentence)

        trl = Trial(condition = trial_type,
                    sentence = sen,
                    picture = pic)

        trials.append(trl)

    return trials


class Simulation(SP_Object):
    def __init__(self, model="pure-procedural.lisp", n=100):
        self.model = model
        self.n = n
        self.data = {c : 0 for c in self.CONDITIONS}
        self.trials = load_trials()
        self.current_condition = None


    def record_response(self, model, response):
        """Records a response in the simulations"""
        if response == 'active':
            self.data[self.current_condition] += 1



    def run_trial(self, trial):
        """A trial"""
        sen = trial.sentence
        pic = trial.picture
        chunk_s = actr.define_chunks(sen.chunk_definition)[0]
        actr.set_buffer_chunk('visual',
                              chunk_s)
        actr.run(time = 10)
        
        chunk_p = actr.define_chunks(pic.chunk_definition)[0]
        actr.schedule_set_buffer_chunk('visual',
                                       chunk_p,
                                       actr.mp_time() + 0.05)
        actr.run(time = 10)


    def simulate(self, trace=False):
        actr.load_act_r_model(self.model)

        if not trace:
            actr.set_parameter_value(":V", False)
        
        for condition in self.CONDITIONS:
            self.current_condition = condition
            subset = [t for t in self.trials if t.condition == condition]
            for j in range(self.n):
                actr.reset()
        
                # The model does not really need a visual interface,
                # but the default AGI provides a virtual mic to record
                # voice output.
        
                win = actr.open_exp_window("SP", width = 80,
                                           height = 60,
                                           visible=False)
                actr.install_device(win)
                actr.add_command("record-response", self.record_response,
                                 "Accepts a response for the SP task")
                actr.monitor_command("output-speech",
                                     "record-response")
                
                trial = random.choice(subset)
                
                run_trial(trial)
                
                actr.remove_command_monitor("output-speech",
                                            "record-response")
                actr.remove_command("record-response")

                
    def __repr__(self):
        return "<SMLTN (%s), N=%d>" % (self.model, self.n)
        
    

