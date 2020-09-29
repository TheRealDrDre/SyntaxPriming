###################### ACT-R + PYTHON TEMPLATE #######################
#   Author: Cher Yang
#   Date: 09/24/2020
# This template provides a init python code for building an ACT-R model

import actr
import random
import os
from datetime import date, datetime
random.seed(0)

actr.load_act_r_model(os.getcwd()+"/model3.lisp")   # load the model


response = False
def respond_to_speech (model, string):
    # print('SELECT...', string, model)
    global response
    response = string

def task1(prime_stimulus):
    prime_sentence = actr.define_chunks(prime_stimulus)[0]
    actr.set_buffer_chunk('visual', prime_sentence) # prime sentence
    # set init goal
    # actr.record_history('buffer-trace', 'vocal')
    actr.goal_focus('wait-for-screen')
    actr.run(10)

def task2(target_stimulus=None):
    target_stimulus = ['isa', 'picture',
                                       'agent', 'n3',
                                       'patient', 'n4',
                                       'action', 'v']
    target_picture = actr.define_chunks(target_stimulus)[0]

    # set second goal
    actr.goal_focus('wait-for-next-screen')
    actr.set_buffer_chunk('visual', target_picture)  # target picture
    actr.run(10)

def ASP(num_trials, shuffle=False):
    trials = []
    prime_template = ['isa', 'sentence',
                                         'string', '...',
                                         'noun1', 'n1',
                                         'noun2', 'n2',
                                         'verb', 'v',
                                         'syntax', 'DO',
                                         'syntax-corr', 'yes']
    # create prime trials

    for i in range(int(num_trials / 4)):
        prime_sentence = prime_template.copy()
        prime_sentence[-3] = 'DO'
        prime_sentence[-1] = 'no'
        trials.append(prime_sentence)
    for i in range(int(num_trials/4)):
        prime_sentence = prime_template.copy()
        prime_sentence[-3] = 'PO'
        prime_sentence[-1] = 'no'
        trials.append(prime_sentence)
    for i in range(int(num_trials / 4)):
        prime_sentence = prime_template.copy()
        prime_sentence[-3] = 'DO'
        prime_sentence[-1] = 'yes'
        trials.append(prime_sentence)
    for i in range(int(num_trials/4)):
        prime_sentence = prime_template.copy()
        prime_sentence[-3] = 'PO'
        prime_sentence[-1] = 'yes'
        trials.append(prime_sentence)
    if shuffle: random.shuffle(trials)
    return trials


def single_trial(prime_stimulus):
    # actr.record_history('buffer-trace', 'goal')
    # actr.set_parameter_value(':v', 't')

    # add command
    actr.add_command("model1-key-press", respond_to_speech,
                     "model1 task output-key monitor")
    actr.monitor_command("output-speech", "model1-key-press")
    global response
    response = False

    task1(prime_stimulus)
    task2()

    actr.remove_command_monitor("output-speech", "model1-key-press")
    actr.remove_command("model1-key-press")
    return response

def exp(num_trials=100, display_data=False):
    actr.reset()
    # prepare exp stimuli
    trials = ASP(num_trials)
    # install speech and microphone device
    actr.install_device(("speech", "microphone"))

    response_list_DOC = []
    response_list_DOI = []
    response_list_POC = []
    response_list_POI = []

    for i in range(num_trials):
        response = single_trial(trials[i])

        syn = trials[i][-3]
        syn_corr = trials[i][-1]
        # print(syn, syn_corr, (syn=='DO') & (syn_corr=='yes'))
        if (syn=='DO') & (syn_corr=='yes'):
            response_list_DOC.append(response)
        elif (syn=='DO') & (syn_corr=='no'):
            response_list_DOI.append(response)
        elif (syn == 'PO') & (syn_corr == 'yes'):
            response_list_POC.append(response)
        else:
            response_list_POI.append(response)

    # calculate proportion of DO after different prime conditions
    prop_DOC = response_list_DOC.count('DO')*4.0/num_trials
    prop_DOI = response_list_DOI.count('DO')*4.0/num_trials
    prop_POC = response_list_POC.count('DO')*4.0/num_trials
    prop_POI = response_list_POI.count('DO')*4.0/num_trials
    if display_data:
        print('-----SUBJ END:-----', num_trials, 'trials')
        print(prop_DOC)#*.25/num_trials)
        print(prop_DOI)#*.25/num_trials)
        print(prop_POC)#*.25/num_trials)
        print(prop_POI)#*.25/num_trials)

    return [prop_DOC, prop_DOI, prop_POC, prop_POI]

def simulations(num_simulation, output_data=True):

    if output_data:
        output_file = open(os.getcwd()+"/simulation_data/"+actr.current_model()+datetime.now().strftime("%Y%m%d%H%M%S")+".txt", "w")
        header="DOC, DOI, POC, POI\n"
        param='ans: {param_ans}; bll: {param_bll}; lf: {param_lf}; egs: {param_egs}; ppm: {param_ppm}\n'\
            .format(param_ans=actr.get_parameter_value(':ans'),
                    param_bll=actr.get_parameter_value(':bll'),
                    param_lf=actr.get_parameter_value(':lf'),
                    param_egs=actr.get_parameter_value(':egs'),
                    param_ppm=actr.get_parameter_value(':ppm')
                    )
        output_file.write(header)
        output_file.write(param)
        for i in range(num_simulation):
            line=exp()
            line=str(line).strip('[]')+"\n"
            output_file.write(line)
            # process bar
            if i % 10 == 0: print('#')
        output_file.close()
    else:
        # simply running it
        for i in range(num_simulation):
            exp()


############ test ############
def test1():
    # only DO trials - 10
    trials = []
    num_trials = 10
    response_list = []
    prime_template = ['isa', 'sentence',
                      'string', '...',
                      'noun1', 'n1',
                      'noun2', 'n2',
                      'verb', 'v',
                      'syntax', 'DO',
                      'syntax-corr', 'yes']
    for i in range(int(num_trials)):
        prime_sentence = prime_template.copy()
        prime_sentence[-3] = 'DO'
        prime_sentence[-1] = 'no'
        trials.append(prime_sentence)

    # insatll device
    actr.reset()
    actr.install_device(("speech", "microphone"))

    for i in range(num_trials):

        response = single_trial(trials[i])

        syn = trials[i][-3]
        syn_corr = trials[i][-1]
        # print("prime:",syn, syn_corr, "resp", response)
        # if response=='failure':
            # print("---------------")
            #actr.sdp('DO-form', 'PO-form')
            #actr.whynot('step6-1')
            # actr.whynot_dm('DO-form', 'PO-form')

        response_list.append(response)
    print("response count()", response_list.count("DO"), response_list.count("PO"), "\ntotal: ", num_trials)
    print("prop_DO", response_list.count("DO")*1.0/(response_list.count("DO")+response_list.count("PO")))

