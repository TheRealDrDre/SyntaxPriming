import pandas as pd
import json
import numpy as np

def rmse(model_data, subj_data):
    """full mrse"""
    R = np.array(model_data)
    D = np.array(subj_data)

    r_DIFF = np.round([np.mean(R[0:2])-np.mean(R[2:4]),
        R[0]-R[1], R[2]-R[3]], 4)
    d_DIFF = np.round([np.mean(D[0:2]) - np.mean(D[2:4]),
                           D[0] - D[1], D[2] - D[3]], 4)
    RMSE = np.sqrt(np.mean((D-R)**2)) + np.sqrt(np.mean((d_DIFF-r_DIFF)**2))
    return(RMSE)

def rmse_diff(model_data, subj_data):
    """this rmse only consider diff"""
    R = np.array(model_data)
    D = np.array(subj_data)

    r_DIFF = np.round([np.mean(R[0:2])-np.mean(R[2:4]),
        R[0]-R[1], R[2]-R[3]], 4)
    d_DIFF = np.round([np.mean(D[0:2]) - np.mean(D[2:4]),
                           D[0] - D[1], D[2] - D[3]], 4)
    RMSE = np.sqrt(np.mean((d_DIFF-r_DIFF)**2))
    return(RMSE)

######## MODEL DATA WIDE FORMAT ############################################
# write in MODEL1_wide.csv
def model1_subjmean_analysis():
    with open("./simulation_data/MODEL1/MODEL120201109.txt") as f:
        data = f.readlines()

    df = pd.DataFrame([json.loads(line.strip()) for line in data])
    df1 = df[['ans', 'bll', 'lf', 'prop_mean', 'prop_sd']]
    #mean_subj_data1  = [.84, .89, .63, .69]

    #df1['ASP1.mean.rmse'] = df1.prop_mean.apply(rmse_diff, args=([mean_subj_data1])) # could be rmse or rmse_diff
    #df1s = df1.sort_values(by='rmse')
    #df1_final = pd.concat([df1s, pd.DataFrame(df1.prop_mean.tolist(), columns=['DOC', 'DOI', 'POC', 'POI'])],
    #                      axis=1).drop(['prop_mean'], axis=1)
    df1_final = pd.concat([df1,
                           pd.DataFrame(df1.prop_mean.tolist(), columns=['DOC', 'DOI', 'POC', 'POI']),
                           pd.DataFrame(df1.prop_sd.tolist(), columns=['DOC_sd', 'DOI_sd', 'POC_sd', 'POI_sd'])],
                          axis=1).drop(['prop_mean', 'prop_sd'], axis=1)
    # df1_final.to_csv("./simulation_data/MODEL1/MODEL120201210_clean.csv") #diff rmse
    return df1_final

# write in MODEL2_wide.csv
def model2_subjmean_analysis():
    with open("./simulation_data/MODEL2/MODEL220201108.txt") as f:
        data2_1 = f.readlines()
    with open("./simulation_data/MODEL2/MODEL220201109.txt") as f:
        data2_2 = f.readlines()

    data = data2_1 + data2_2

    df = pd.DataFrame([json.loads(line.strip()) for line in data])
    df1 = df[['ans', 'bll', 'lf', 'mas', 'ga', 'prop_mean', 'prop_sd']]
    subj_data  = [.84, .89, .63, .69]

    # df1['rmse'] = df1.prop_mean.apply(rmse)
    # df1['rmse'] = df1.prop_mean.apply(rmse_diff, args=([subj_data]))  # could be rmse or rmse_diff
    # df1s = df1.sort_values(by='rmse')
    df1_final = pd.concat([df1, pd.DataFrame(df1.prop_mean.tolist(), columns=['DOC', 'DOI', 'POC', 'POI']),
                           pd.DataFrame(df1.prop_sd.tolist(), columns=['DOC_sd', 'DOI_sd', 'POC_sd', 'POI_sd'])],
                          axis=1).drop(['prop_mean', 'prop_sd'], axis=1)

    # df1_final.to_csv("./simulation_data/MODEL2/MODEL2_wide.csv")  # diff rmse
    return df1_final

# write in MODEL3_wide.csv
def model3_subjmean_analysis():
    with open("./simulation_data/MODEL3/MODEL320201109.txt") as f:
        data = f.readlines()

    df = pd.DataFrame([json.loads(line.strip()) for line in data])
    df1 = df[['alpha', 'egs', 'r1', 'r2', 'prop_mean', 'prop_sd']]
    # subj_data  = [.84, .89, .63, .69]

    # df1['rmse'] = df1.prop_mean.apply(rmse)
    # df1['rmse'] = df1.prop_mean.apply(rmse_diff, args=([subj_data]))  # could be rmse or rmse_diff
    # df1s = df1.sort_values(by='rmse')
    df1_final = pd.concat([df1, pd.DataFrame(df1.prop_mean.tolist(), columns=['DOC', 'DOI', 'POC', 'POI']),
                           pd.DataFrame(df1.prop_sd.tolist(), columns=['DOC_sd', 'DOI_sd', 'POC_sd', 'POI_sd'])],
                          axis=1).drop(['prop_mean', 'prop_sd'], axis=1)

    # df1_final.to_csv("./simulation_data/MODEL3/MODEL3_wide.csv")  # diff rmse
    return df1_final

############################################################################
def individual_fit_asp1(subj1, model1):
    # load wide format of subj data
    # subj1 = pd.read_csv('./subj_data/ASP1/ASP1_subj_wide90.csv')
    # load wide format of model data
    # model1 = pd.read_csv('./simulation_data/MODEL1/MODEL1_wide.csv')

    # chaneg model's col name to match
    model1 = model1.rename(columns={'Unnamed: 0': 'mid', "DOC": "mAC", "DOI": "mAI", "POC":"mPC", "POI":"mPI"})

    subj_fit = pd.DataFrame()
    for index, srow in subj1.iterrows():
        subj_i = [srow['AC'], srow['AI'], srow['PC'], srow['PI']]
        best_rmse = 100

        for mindex, mrow in model1.iterrows():
            model_i = [mrow['mAC'], mrow['mAI'], mrow['mPC'], mrow['mPI']]

            # standard rmse
            #curr_rmse = rmse(model_i, subj_i)
            curr_rmse = rmse(model_i, subj_i)
            if curr_rmse < best_rmse:
                best_rmse = curr_rmse
                best_mrow = mrow
                print('best_rmse',curr_rmse)


            if mindex == model1.last_valid_index():

                best_mrow['min_rmse'] = best_rmse
                #best_mrow['subjID'] = int(srow['subjID'])
                print('>> finish one subj', srow['subjID'])

        subj_fit = subj_fit.append(best_mrow, ignore_index=True)

    #subj_fit = subj_fit.rename(columns={'Unnamed: 0': 'mid'})
    subj_fit = pd.concat([subj1, subj_fit], axis=1)
    return subj_fit
    # subj_fit.to_csv('./simulation_data/MODEL1/ASP1MODEL1_reg.csv')


def individual_fit_asp3(subj3, model1):
    # load wide format of subj data
    # subj3 = pd.read_csv('./subj_data/ASP3/ASP3_subj_wide.csv')
    # load wide format of model data
    # model1 = pd.read_csv('./simulation_data/MODEL1/MODEL1_wide.csv')
    # chaneg model's col name to match
    model1 = model1.rename(columns={"Unnamed: 0": "mid", "DOC": "mDOC", "DOI": "mDOI", "POC":"mPOC", "POI":"mPOI"})

    subj_fit = pd.DataFrame()
    for index, srow in subj3.iterrows():
        subj_i = [srow['DOC'], srow['DOI'], srow['POC'], srow['POI']]
        best_rmse = 100

        for mindex, mrow in model1.iterrows():
            model_i = [mrow['mDOC'], mrow['mDOI'], mrow['mPOC'], mrow['mPOI']]
            #curr_rmse = rmse(model_i, subj_i)
            curr_rmse = rmse(model_i, subj_i)

            if curr_rmse < best_rmse:
                best_rmse = curr_rmse
                best_mrow = mrow
                print('best_rmse', best_rmse)

            if mindex == model1.last_valid_index():
                best_mrow['min_rmse'] = best_rmse
                print('>> finish one subj', srow['surveyID'])

        subj_fit = subj_fit.append(best_mrow, ignore_index=True)

    #subj_fit = subj_fit.rename(columns={'Unnamed: 0': 'mid'})
    subj_fit = pd.concat([subj3, subj_fit], axis=1)
    return subj_fit
    # subj_fit.to_csv('./simulation_data/MODEL1/ASP3MODEL1_reg.csv')

#~~~~~~~~~~~~~~~~~~~~~~~ convert z

def convert_z(model_data, subj_mean, subj_sd):
    """subj_data = mean of subj"""
    subj1 = pd.read_csv("./simulation_data/MODEL1/ASP1MODEL1_reg.csv", usecols=['subjID', 'AC', 'AI', 'PC', 'PI', 'resp_accuracy', 'missing_entries'])
    model1 = pd.read_csv("./simulation_data/MODEL1/MODEL1_wide.csv")

    for srow in subj1.iterrows():
        ind = pd.DataFrame()


    model_data=np.array(model_data)
    subj_mean=np.array(subj_mean)
    subj_sd=np.array(subj_sd)
    return (model_data - subj_mean)/subj_sd







