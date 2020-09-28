###################### ACT-R + PYTHON TEMPLATE #######################
#   Author: Cher Yang
#   Date: 09/24/2020
# This template provides a init python code for building an ACT-R model

import actr
import random
actr.load_act_r_model("/Users/cheryang/Documents/Code/ACT-R_PyProjects/model1.lisp")   # load the model

# set param
#actr.set_parameter_value(':alpha', 0.9)

response = False
def respond_to_speech (model, string):
    print('SELECT...', string, model)
    global response
    response = string

def task1(prime_stimulus):
    prime_sentence = actr.define_chunks(prime_stimulus)[0]
    actr.set_buffer_chunk('visual', prime_sentence) # prime sentence
    # set init goal
    # actr.record_history('buffer-trace', 'vocal')
    actr.goal_focus('wait-for-screen')
    actr.run(1)

def task2(target_stimulus=None):
    target_stimulus = ['isa', 'picture',
                                       'agent', 'n3',
                                       'patient', 'n4',
                                       'action', 'v']
    target_picture = actr.define_chunks(target_stimulus)[0]

    # set second goal
    if actr.current_model()=="MODEL3":
        actr.goal_focus('wait-for-next-screen')
    elif actr.current_model() == "MODEL1":
        actr.goal_focus('wait-for-screen')
    else:
        print('fail to set goal')
        return
    actr.set_buffer_chunk('visual', target_picture)  # target picture
    actr.run(1)

def ASP(num_trials, shuffle=True):
    trials = []
    prime_template = ['isa', 'sentence',
                                         'string', '...',
                                         'noun1', 'n1',
                                         'noun2', 'n2',
                                         'verb', 'v',
                                         'syntax', 'DO',
                                         'syntax-corr', 'yes']

    # create prime trials
    for i in range(int(num_trials/4)):
        prime_sentence = prime_template.copy()
        prime_sentence[-3] = 'DO'
        prime_sentence[-1] = 'yes'
        trials.append(prime_sentence)
    for i in range(int(num_trials/4)):
        prime_sentence = prime_template.copy()
        prime_sentence[-3] = 'DO'
        prime_sentence[-1] = 'no'
        trials.append(prime_sentence)
    for i in range(int(num_trials/4)):
        prime_sentence = prime_template.copy()
        prime_sentence[-3] = 'PO'
        prime_sentence[-1] = 'yes'
        trials.append(prime_sentence)
    for i in range(int(num_trials/4)):
        prime_sentence = prime_template.copy()
        prime_sentence[-3] = 'PO'
        prime_sentence[-1] = 'no'
        trials.append(prime_sentence)

    if shuffle: random.shuffle(trials)
    return trials


def single_trial(prime_stimulus):
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

def exp(num_trials=100, display_data=True):
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
        # actr.spp('step2-1', ':u')
        # actr.spp('step2-2', ':u')


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

def simulations(num_simulation, output_data=False):
    if output_data:
        output_file = open("/Users/cheryang/Documents/Code/ACT-R_PyProjects/Trace/"+actr.current_model()+".txt", "w")
        header="DOC, DOI, POC, POI\n"
        output_file.write(header)
        for i in range(num_simulation):
            line=exp()
            line=str(line).strip('[]')+"\n"
            output_file.write(line)
        output_file.close()
    else:
        # simply running it
        for i in range(num_simulation):
            exp()