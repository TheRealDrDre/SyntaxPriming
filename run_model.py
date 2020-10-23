###################### ACT-R + PYTHON TEMPLATE #######################
#   Author: Cher Yang
#   Date: 09/24/2020
# This template provides a init python code for building an ACT-R model

import actr
import random
import os
import numpy as np
from datetime import date, datetime
from tqdm import tqdm

random.seed(0)

actr.load_act_r_model(os.getcwd()+"/model1.lisp")   # load the model

subj_data = [0.756, 0.786, 0.595, 0.548]

response = False
def respond_to_speech (model, string):
    """
    This function collect the speech response from the model
    :param model: string, model1/model2/model3
    :param string: speech response generated from the model simulation, (e.g. DO/PO)
    :return:
    """
    # print('SELECT...', string, model)
    global response
    response = string

def task1(prime_stimulus):
    """
    This function simulates the prime sentence verification task. The model parses in the prime sentence,
    and attempts to comprehend it.
    :param prime_stimulus: list, for simplification,
                           assumes only syntax and syntax-corr changes based on condition
    :return:
    """
    prime_sentence = actr.define_chunks(prime_stimulus)[0]
    actr.set_buffer_chunk('visual', prime_sentence) # prime sentence
    # set init goal
    # actr.record_history('buffer-trace', 'vocal')
    actr.goal_focus('wait-for-screen')
    actr.run(10)

def task2(target_stimulus=None):
    """
    This function simulates the picture description task. The model observes the picture stimuli
    and attempts to describe the picture using one of potential syntactic structure.
    :param target_stimulus: None, for simplification,
                            assume the picture stimuli uses the same verb as prime sentence
    :return:
    """
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
    """
    Create a ASP paradigm trials
    :param num_trials: int, number of trials, need to be 4*n
    :param shuffle: whether randomly shuffle the list
    :return: list, generated ASP trials
    """
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
        prime_sentence[-1] = 'yes'
        trials.append(prime_sentence)
    for i in range(int(num_trials/4)):
        prime_sentence = prime_template.copy()
        prime_sentence[-3] = 'PO'
        prime_sentence[-1] = 'yes'
        trials.append(prime_sentence)
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
    if shuffle: random.shuffle(trials)
    return trials


def single_trial(prime_stimulus):
    """
    This function simulates an single trial. At the begining of each trial, the model is reset.
    The model's response is collected as either DO/PO for a simplified version of full sentence
    :param prime_stimulus: dict type, the prime stimulus, indicating the condition
    :return:
    """
    actr.reset()
    # actr.record_history('BUFFER-TRACE','production-graph-utility')
    actr.install_device(("speech", "microphone"))
    # actr.record_history('buffer-trace', 'goal')
    # actr.set_parameter_value(':v', 't')
    syntax = prime_stimulus[-3]
    syntax_corr = prime_stimulus[-1]

    actr.add_command("model1-key-press", respond_to_speech,
                     "model1 task output-key monitor")
    actr.monitor_command("output-speech", "model1-key-press")

    # MODEL1: spreading activation
    # if actr.current_model()=="MODEL1":
    #     if syntax_corr == 'no':
    #         actr.pdisable("step5-1")
    #         actr.pdisable("step5-2")
    #     else:
    #         actr.pdisable('step5-3')
    #         if syntax == 'DO':
    #             actr.pdisable("step5-2")
    #         else:
    #             actr.pdisable("step5-1")

    global response
    response = False

    task1(prime_stimulus)
    task2()

    actr.remove_command_monitor("output-speech", "model1-key-press")
    actr.remove_command("model1-key-press")

    # if display:
    #     print(actr.get_history_data('production'))
    #     print(actr.used_production_buffers())
        # actr.print_chunk_activation_trace('DO-FORM', 1750)
        # actr.print_chunk_activation_trace('PO-FORM', 1750)
    return response

def exp(num_trials=40, display_data=False):
    """
    :param num_trials: the number of trials in the experiment
    :param display_data: whether display data
    :return:
    """
    # prepare exp stimuli
    trials = ASP(num_trials)
    # install speech and microphone device

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
    simulated_data = [prop_DOC, prop_DOI, prop_POC, prop_POI]
    return simulated_data

def simulations(num_simulation, display_data=True):
    """
    This function run the simulation with with a set of parameter set
    :param num_simulation: int, the number of epochs simulation
    :param output_data: True/False, the number of epochs simulation
    :return: correlation
    """

    # get parameters
    param = ''
    if actr.current_model()=="MODEL1":
        param = get_parameters('ans', 'bll', 'lf', 'imaginal-activation', 'mas')
    elif actr.current_model()=="MODEL2":
        param = get_parameters('alpha', 'egs', 'r1', 'r2')
    elif actr.current_model()=="MODEL3":
        param = get_parameters('alpha', 'egs', 'r1', 'r2', 'ppm', 'similarities')

    sum_simulation = []
    # write data
    output_file = open(os.getcwd()+"/simulation_data/"+actr.current_model()+datetime.now().strftime("%Y%m%d%H%M%S")+".txt", "w")
    header="DOC, DOI, POC, POI"
    output_file.write(header+'\n')
    output_file.write(param+'\n')
    for i in range(num_simulation):
        line=exp()
        sum_simulation.append(line) # calculate mean
        line=str(line).strip('[]')+"\n"
        output_file.write(line)
    output_file.close()

    # calculate mean
    mean_simulation = list(np.mean(np.array(sum_simulation), axis=0))
    corr = actr.correlation(subj_data, mean_simulation, False)
    if display_data:
        print(param, mean_simulation, corr)
    return corr


def set_parameters(**kwargs):
    """
    set parameter to current model
    :param kwargs: dict pair, indicating the parameter name and value (e.g. ans=0.1, r1=1, r2=-1)
    :return:
    """
    for key, value in kwargs.items():
        # set reward parameter
        if key=='r1':
            actr.spp('step3-1', ':reward', value)
        elif key=='r2':
            actr.spp('step3-2', ':reward', value)
        elif key=='similarities' and actr.current_model()=='MODEL3':
            # set-similarities (DO undecided 0.5) (PO undecided 0.5)
            actr.sdp('undecided', ":similarities", [['DO', value], ['PO', value]])
            actr.sdp('DO', ":similarities", [['undecided', value]])
            actr.sdp('PO', ":similarities", [['undecided', value]])
        # normal parameters
        else:
            actr.set_parameter_value(':' + key, value)


def get_parameters(*keys):
    """
    get parameter from current model
    :param keys: string, the parameter name (e.g. ans, bll, r1, r2)
    :return:
    """
    paramstr = ""
    for key in keys:
        # get reward parameter
        if key == 'r1':
            rs = [x[0] for x in actr.spp(':reward') if x != [None]]
            if len(rs)==0:
                v1 = None
                v2 = None
            else:
                v1=rs[0]
                v2=rs[1]
            paramstr += 'r1: {param_r1}; r2: {param_r2}; ' \
                .format(param_r1=v1, param_r2=v2)
        elif key == 'r2':
            continue
        elif key == 'similarities':
            s1=actr.sdp('DO', ":similarities")[0][0][-1][-1] # get the DO-Undecided Similarities
            paramstr += 'similarities: {param_similarities}; ' \
                .format(param_similarities=s1)
        # normal parameter
        else:
            paramstr += '{param_name}: {param}; ' \
                .format(param_name=key, param=actr.get_parameter_value(':'+key))
    return paramstr

############ test ############
def test1():
    # only DO trials - 10
    trials = []
    num_trials = 1
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
        prime_sentence[-1] = 'yes'
        trials.append(prime_sentence)

    actr.reset()

    # insatll device
    actr.install_device(("speech", "microphone"))

    for i in range(num_trials):
        response = single_trial(trials[i])
        syn = trials[i][-3]
        syn_corr = trials[i][-1]
        print("prime:",syn, syn_corr, "resp:", response)
        # if response=='failure':
            # print("---------------")
            #actr.sdp('DO-form', 'PO-form')
            #actr.whynot('step6-1')
            # actr.whynot_dm('DO-form', 'PO-form')

        response_list.append(response)
    print("response count()", 
        "DO:", response_list.count("DO"), 
        "PO:", response_list.count("PO"), "\ntotal: ", num_trials)
    print("prop_DO", response_list.count("DO")*1.0/(response_list.count("DO")+response_list.count("PO")))

def test2(syntax, syntax_corr):

    actr.reset()
    prime_template = ['isa', 'sentence',
                      'string', '...',
                      'noun1', 'n1',
                      'noun2', 'n2',
                      'verb', 'v',
                      'syntax', syntax,
                      'syntax-corr', syntax_corr]

    actr.add_command("model1-key-press", respond_to_speech,
                     "model1 task output-key monitor")
    actr.monitor_command("output-speech", "model1-key-press")
    # spreading activation
    # if syntax_corr == 'no':
    #     print('disable both')
    #     actr.pdisable("step5-1")
    #     actr.pdisable("step5-2")
    # else:
    #     actr.pdisable('step5-3')
    #     if syntax == 'DO':
    #         print('disable5-2')
    #         actr.pdisable("step5-2")
    #     else:
    #         print('disable5-1')
    #         actr.pdisable("step5-1")

    global response
    response = False

    task1(prime_template)
    task2()

    actr.remove_command_monitor("output-speech", "model1-key-press")
    actr.remove_command("model1-key-press")
    return response

# find best parameter for model1
def test3():
    actr.load_act_r_model(os.getcwd() + "/model1.lisp")  # load the model
    ans = [0.2, 0.5, 0.8]
    bll = [0.2, 0.5, 0.8]
    mas = [1.3, 1.6, 1.9]
    ia = [0.5, 1, 1.5]
    hyper_param = [{'ans':i, 'bll':j, 'mas':k, 'imaginal-activation':l} \
                   for i in ans for j in bll for k in mas for l in ia]
    best_corr = -2
    best_param = []
    for i in tqdm(range(len(hyper_param))):
        param_set = hyper_param[i]
        set_parameters(**param_set)
        corr = simulations(50)
        if corr > best_corr:
            best_corr = corr
            best_param = param_set
    print(">> best_corr", "best_param\n")
    print(best_corr, best_param)
    return (best_corr, best_param)

# test simulation for three models
def test4():
    print("############# MODEL1 #############")
    actr.load_act_r_model(os.getcwd() + "/model1.lisp")  # load the model
    simulations(100)

    print("############# MODEL2 #############")
    actr.load_act_r_model(os.getcwd() + "/model2.lisp")  # load the model
    simulations(100)

    print("############# MODEL3 #############")
    actr.load_act_r_model(os.getcwd() + "/model3.lisp")  # load the model
    simulations(100)

# find best parameter for model2
def test5():
    # grid search hyper-parameter tuning
    alpha = [0.001, 0.01, 0.1, 0.2, 0.3]
    egs = [0.0, 0.3, 0.6, 0.9, 1.2, 1.5]
    r2 = [-0.1, -0.5, -1, -5, -10]
    ppm = [0, 1, 1.5]
    #hyper_param = [[i, j] for i in alpha for j in egs]
    hyper_param = [{'alpha':i, 'egs':j, 'r2':k, 'ppm':l} for i in alpha for j in egs for k in r2 for l in ppm]

    actr.load_act_r_model(os.getcwd() + "/model3.lisp")  # load the model
    best_corr = -2
    best_param = []
    for i in tqdm(range(len(hyper_param))):
        param_set=hyper_param[i]
        set_parameters(**param_set)
        corr = simulations(50)
        if corr > best_corr:
            best_corr = corr
            best_param = param_set
    print(">> best_corr", "best_param\n")
    print(best_corr, best_param)
    return (best_corr, best_param)

# find best parameter for model3
def test6():
    import pandas as pd
    data_files = [f for f in os.listdir('simulation_data') if 'MODEL320201022' in f]
    best_corr = -2
    best_file = ''
    for f in data_files:
        df=pd.read_csv('simulation_data/'+f, header=0, skiprows=[1])
        sim_mean=list(df.mean())
        corr = actr.correlation(sim_mean, subj_data, False)
        if corr > best_corr:
            best_corr=corr
            best_file=f
            print('for now, best corr', corr, 'sim_mean', sim_mean)
    print('>>> overall best corr', best_corr, best_file)


