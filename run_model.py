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
import json
from copy import *

random.seed(0)
subj_data = [0.756, 0.786, 0.595, 0.548]  # type: List[float]
actr.load_act_r_model(os.getcwd() + "/model2.lisp")

curr_param = False
# param_key = False
global response

############ PARAM ############
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
    paramdict = {}
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
            paramdict['r1']=v1
            paramdict['r2'] = v2
        elif key == 'r2':
            continue
        elif key == 'similarities':
            s1=actr.sdp('DO', ":similarities")[0][0][-1][-1] # get the DO-Undecided Similarities
            paramdict['similarities']=s1
        # normal parameter
        else:
            paramdict[key] = actr.get_parameter_value(':'+key)
    return paramdict

def find_parameters():
    # global param_key
    # get parameters
    if actr.current_model() == "MODEL1":
        param_key = ['ans', 'bll', 'lf']
    elif actr.current_model() == "MODEL2":
        param_key = ['ans', 'bll', 'lf', 'ga', 'mas']
    elif actr.current_model() == "MODEL3":
        param_key = ['alpha', 'egs', 'r1', 'r2', 'ppm']
    elif actr.current_model() == "MODEL4":
        param_key = ['alpha', 'egs', 'r1', 'r2', 'ppm', 'similarities']

    return param_key

############ MODEL ############

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
        prime_sentence = copy(prime_template)
        prime_sentence[-3] = 'DO'
        prime_sentence[-1] = 'yes'
        trials.append(prime_sentence)
    for i in range(int(num_trials/4)):
        prime_sentence = copy(prime_template)
        prime_sentence[-3] = 'PO'
        prime_sentence[-1] = 'yes'
        trials.append(prime_sentence)
    for i in range(int(num_trials / 4)):
        prime_sentence = copy(prime_template)
        prime_sentence[-3] = 'DO'
        prime_sentence[-1] = 'no'
        trials.append(prime_sentence)
    for i in range(int(num_trials/4)):
        prime_sentence = copy(prime_template)
        prime_sentence[-3] = 'PO'
        prime_sentence[-1] = 'no'
        trials.append(prime_sentence)
    if shuffle: random.shuffle(trials)
    return trials

# def ASP_cond(num_trials, syn='DO', syn_corr='yes'):
#     trials = []
#     prime_template = ['isa', 'sentence',
#                       'string', '...',
#                       'noun1', 'n1',
#                       'noun2', 'n2',
#                       'verb', 'v',
#                       'syntax', 'DO',
#                       'syntax-corr', 'yes']
#     for i in range(int(num_trials)):
#         prime_sentence = prime_template.copy()
#         prime_sentence[-3] = syn
#         prime_sentence[-1] = syn_corr
#         trials.append(prime_sentence)
#     return trials

def single_trial(prime_stimulus, **param_set):
    """
    This function simulates an single trial. At the begining of each trial, the model is reset.
    The model's response is collected as either DO/PO for a simplified version of full sentence
    :param prime_stimulus: dict type, the prime stimulus, indicating the condition
    :return:
    """

    global response
    response = False

    while not response:
        actr.reset()
        actr.install_device(("speech", "microphone"))
        if param_set: set_parameters(**param_set)        #reset param
        # actr.record_history('BUFFER-TRACE','production-graph-utility')

        # actr.record_history('buffer-trace', 'goal')
        # actr.set_parameter_value(':v', 't')
        syntax = prime_stimulus[-3]
        syntax_corr = prime_stimulus[-1]

        actr.add_command("model1-key-press", respond_to_speech,
                         "model1 task output-key monitor")
        actr.monitor_command("output-speech", "model1-key-press")



        task1(prime_stimulus)
        task2()

        actr.remove_command_monitor("output-speech", "model1-key-press")
        actr.remove_command("model1-key-press")

    return response

def exp(num_trials=40, display_data=False, **param_set):
    """
    :param num_trials: the number of trials in the experiment
    :param display_data: whether display data
    :return:
    """

    # prepare exp stimuli
    trials = ASP(num_trials)


    response_list_DOC = []
    response_list_DOI = []
    response_list_POC = []
    response_list_POI = []

    for i in range(num_trials):
        response = single_trial(trials[i], **param_set)

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
    DOC_countDO = response_list_DOC.count('DO')
    DOC_countPO = response_list_DOC.count('PO')

    DOI_countDO = response_list_DOI.count('DO')
    DOI_countPO = response_list_DOI.count('PO')

    POC_countDO = response_list_POC.count('DO')
    POC_countPO = response_list_POC.count('PO')

    POI_countDO = response_list_POI.count('DO')
    POI_countPO = response_list_POI.count('PO')

    prop_DOC = DOC_countDO*1.0/len(response_list_DOC)
    prop_DOI = DOI_countDO*1.0/len(response_list_DOI)
    prop_POC = POC_countDO*1.0/len(response_list_POC)
    prop_POI = POI_countDO*1.0/len(response_list_POI)

    logodds_DOC = np.log(prop_DOC / (1-prop_DOC+1e-5) + 1e-5)
    logodds_DOI = np.log(prop_DOI / (1-prop_DOI+1e-5) + 1e-5)
    logodds_POC = np.log(prop_POC / (1-prop_POC+1e-5) + 1e-5)
    logodds_POI = np.log(prop_POI / (1-prop_POI+1e-5) + 1e-5)

    prop_data = [prop_DOC, prop_DOI, prop_POC, prop_POI]
    logodds_data = [logodds_DOC, logodds_DOI, logodds_POC, logodds_POI]
    if display_data:
        print('-----EXP END:-----', num_trials, 'trials')
        print('>> mean simulated data >>', prop_data)
        print('>> log odds data >>', logodds_data)
        print('>>>>>> curr simulation - curr param:', get_parameters(*find_parameters()))
        print('>> countDO', DOC_countDO,DOI_countDO,POC_countDO,POI_countDO)
        print('>> countPO', DOC_countPO, DOI_countPO, POC_countPO, POI_countPO)
        print('>> response list', response_list_DOC, response_list_DOI, response_list_POC, response_list_POI)

    return (prop_data, logodds_data)

def simulations(num_simulation=2, print_data=False, **param_set):
        """
        This function run the simulation with with a set of parameter set
        :param num_simulation: int, the number of epochs simulation
        :param output_data: True/False, the number of epochs simulation
        :return: simulation results, dict {'mean':[double], 'sd':[double], 'ans'...}
        """
        # curr_param = get_parameters(*find_parameters()).copy()


        # calcualte mean data
        prop_simulation = []
        logodds_simulation = []
        for i in range(num_simulation):
            prop_data, logodds_data = exp(**param_set)
            prop_simulation.append(prop_data)
            logodds_simulation.append(logodds_data)

        prop_mean = list(np.mean(np.array(prop_simulation), axis=0))
        prop_sd = list(np.std(np.array(prop_simulation), axis=0))

        logodds_mean = list(np.mean(np.array(logodds_simulation), axis=0))
        logodds_sd = list(np.std(np.array(logodds_simulation), axis=0))

        if curr_param:
            res = copy(curr_param)
        else:
            res = get_parameters(*find_parameters()) # defalt param_set

        if print_data:
            print('>> simulated mean >>', prop_mean)
            print('>> simulated std >>', prop_sd)
            print('>>>>>> curr simulation - curr param:', res)
        res['prop_mean'] = prop_mean
        res['prop_sd'] = prop_sd
        res['logodds_mean'] = logodds_mean
        res['logodds_sd'] = logodds_sd
        return res

def grid_search_simulation():
    if actr.current_model()=='MODEL1':
        ans = [0.1, 0.25, 0.5, 0.75, 1.0, 1.5]
        bll = [.1, .3, .5, .7, .9]
        lf = [.1, .3, .5, .7, .9]
        hyper_param = [[i, j, k] for i in ans for j in bll for k in lf]
    elif actr.current_model() == 'MODEL2':
        ans = [0.1, 0.25, 0.5, 0.75, 1.0, 1.5]
        bll = [.1, .3, .5, .7, .9]
        lf = [.5, .7, .9, 1]
        mas = [2.8, 3.2, 3.6]
        ga = [0.5, 1.0, 1.5, 2.0]
        hyper_param = [[i, j, k, l, m] for i in ans for j in bll for k in lf for l in mas for m in ga]
    # global param_key
    param_key=find_parameters()

    for i in tqdm(range(2)):
        param_set = dict(zip(param_key, hyper_param[i]))
        line = simulations(**param_set)
        with open(os.getcwd()+"/simulation_data/"+actr.current_model()+datetime.now().strftime("%Y%m%d")+".txt", "a") as f:
            f.write(json.dumps(line)+'\n')

# def rmse(**param_set):
#     """
#     Calculates RMSE for ASP3 data (objective function to minimize)
#     :return: float, rmse
#     """
#
#     m, sd = simulations(50, **param_set)
#     R = np.array(m)
#     D = np.array(subj_data)
#
#     r_DIFF = np.round([np.mean(R[0:2])-np.mean(R[2:4]),
#         R[0]-R[1], R[2]-R[3]], 4)
#     d_DIFF = np.round([np.mean(D[0:2]) - np.mean(D[2:4]),
#                        D[0] - D[1], D[2] - D[3]], 4)
#     # RMSE = np.sqrt(np.mean((D-R)**2)) + np.sqrt(np.mean((d_DIFF-r_DIFF)**2))
#     RMSE = np.sqrt(np.mean((d_DIFF-r_DIFF)**2))
#     return(RMSE)

# def target_func(param_values):
#     find_parameters()
#     param_set = dict(zip(param_key, param_values))
#     res = rmse(**param_set)
#
#     # write simulation data in file
#     minimize_data = dict(zip(param_key, param_values))
#     minimize_data['rmse'] = res
#     with open(os.getcwd() + "/simulation_data/" + actr.current_model() + '_param_optimization.txt', 'a') as f:
#         f.write(json.dumps(minimize_data)+'\n')
#     return(res)

# def minimize_rmse():
#     from scipy.optimize import minimize
#     init = [1.0, 0.2]
#     #model1: ans, bll, lf
#     #model2: ans, bll, lf, mas, ga
#     # init = {'ans': 0, 'bll':0.1, 'lf':0.1}
#     # bounds = [(0, 5), (0, 5), (0, 5), (0, 5)]
#     # target_func(init)
#     minimize(target_func, init, method="nelder-mead", options={"maxiter": 100, "xatol": 1e-2, "fatol": 1e-4, "return_all":True})

# def minimize_rmse_gs():
#     from scipy.optimize import minimize
#     # grid search hyper-parameter tuning
#     # ans = [0.1, 0.5, 1.0, 1.5]
#     # bll = [.1, .3, .5, .7, .9]
#     # lf = [.5, .7, .9]
#     # mas = [2.8, 3.2, 3.6]
#     ga = [0.5, 1.0, 1.5, 2.0]
#
#     # hyper_param = [[i, j] for i in bll for j in lf]
#     # hyper_param = [[i, j, k, l] for i in bll for j in lf for k in mas for l in ga]
#
#     alpha=[.2, .5, .9]
#     egs=[.1, .5, .9]
#     r1=[.1, .5, 1, 5]
#     r2=[-5, -1, -.5, -.1]
#     hyper_param = [[i, j, k, l] for i in alpha for j in egs for k in r1 for l in r2]
#
#
#     min_rmse = 1
#     best_param = []
#     for param in hyper_param:
#         curr_rmse = target_func(param)
#         if curr_rmse < min_rmse:
#             min_rmse = curr_rmse
#             best_param = param
#             print('best_param', best_param, curr_rmse)
#     return (min_rmse, best_param)
#     # hyper_param = [{'alpha': i, 'egs': j, 'r2': k, 'ppm': l} for i in alpha for j in egs for k in r2 for l in ppm]


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
        prime_sentence = copy(prime_template)
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
    simulations(50)

    print("############# MODEL2 #############")
    actr.load_act_r_model(os.getcwd() + "/model2.lisp")  # load the model
    simulations(50)

    print("############# MODEL3 #############")
    actr.load_act_r_model(os.getcwd() + "/model3.lisp")  # load the model
    simulations(50)

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

# test whether param is updated
def test_simulations(num_simulation=1, **param_set):
    global curr_param
    curr_param = param_set
    sum_simulation = []
    for i in range(num_simulation):
        sum_simulation.append(exp(40, True))
    mean_simulation = list(np.mean(np.array(sum_simulation), axis=0))
    # print('>> mean simulated data >>', mean_simulation)
    # param_set = {'ans': 0.5, 'bll': 0.3, 'lf': 0.3, 'style-warnings':'t'}
    # print('>>>>>> curr simulation - curr param:', get_parameters(*param_set.keys()))
