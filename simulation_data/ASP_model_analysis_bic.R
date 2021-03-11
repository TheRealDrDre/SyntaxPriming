library(tidyverse)
library(gtools)
library(ggpubr)
library(rstatix)
library(ggpubr)
rm(list = ls())

# load files 
#subj1 <- read_csv("./MODEL1/ASP1MODEL1_reg.csv") %>% select(X1:missing_entries)
#subj2 <- read_csv("./MODEL1/ASP3MODEL1_reg.csv") %>% select(X1:missing_entries) %>% rename(subjID=surveyID, AC=DOC, AI=DOI, PC=POC, PI=POI)
#subj2.bad <- subj2 %>% filter(missing_entries > 4)
#subj2 <- subj2 %>% anti_join(subj2.bad) 

#model1 = read_csv('./MODEL1/MODEL1_wide.csv') %>% rename(AC.m=DOC,AI.m=DOI,PC.m=POC, PI.m=POI, AC.sd=DOC_sd,AI.sd=DOI_sd,PC.sd=POC_sd, PI.sd=POI_sd)
#model2 = read_csv('./MODEL2/MODEL2_wide.csv') %>% rename(AC.m=DOC,AI.m=DOI,PC.m=POC, PI.m=POI, AC.sd=DOC_sd,AI.sd=DOI_sd,PC.sd=POC_sd, PI.sd=POI_sd)
#model3 = read_csv('./MODEL3/MODEL3_wide.csv') %>% rename(AC.m=DOC,AI.m=DOI,PC.m=POC, PI.m=POI, AC.sd=DOC_sd,AI.sd=DOI_sd,PC.sd=POC_sd, PI.sd=POI_sd)
#load("./ASP_model_data.RData")
load("./ASP_model_data_full.Data")



model1.long = subset(model1 %>% gather('P_type', 'prop', AC.m:PI.sd), grepl(".m$", P_type)) %>%
  mutate(P_type=str_remove(P_type, ".m$")) %>%
  left_join(subset(model1 %>% gather('P_type', 'prop', AC.m:PI.sd), grepl(".sd$", P_type)) %>%
              mutate(P_type=str_remove(P_type, ".sd$")), by = c("mid", "ans", "bll", "lf", "P_type"), suffix=c(".m", '.sd')
  ) %>%
  mutate(prop.se=prop.sd/sqrt(50))

model2.long = subset(model2 %>% gather('P_type', 'prop', AC.m:PI.sd), grepl(".m$", P_type)) %>%
  mutate(P_type=str_remove(P_type, ".m$")) %>%
  left_join(subset(model2 %>% gather('P_type', 'prop', AC.m:PI.sd), grepl(".sd$", P_type)) %>%
              mutate(P_type=str_remove(P_type, ".sd$")), by = c("mid", "ans", "bll", "lf", "mas", "ga", "P_type"), suffix=c(".m", '.sd')
  ) %>%
  mutate(prop.se=prop.sd/sqrt(50))

model3.long = subset(model3 %>% gather('P_type', 'prop', AC.m:PI.sd), grepl(".m$", P_type)) %>%
  mutate(P_type=str_remove(P_type, ".m$")) %>%
  left_join(subset(model3 %>% gather('P_type', 'prop', AC.m:PI.sd), grepl(".sd$", P_type)) %>%
              mutate(P_type=str_remove(P_type, ".sd$")), by = c("mid", "alpha", "egs", "r1", "r2", "P_type"), suffix=c(".m", '.sd')
  ) %>%
  mutate(prop.se=prop.sd/sqrt(50))

# model1.long %>%
#   filter(ans==1 & bll==.1 & lf==.3) %>%
#   ggbarplot(x = 'P_type', y = 'prop.m',
#             label = TRUE, label.pos = "in",  lab.nb.digits = 2, lab.vjust = 5, size = 1,
#             col = 'P_type', palette = 'jco', position = position_dodge(0.8)) + 
#   geom_errorbar(mapping=aes(x=P_type, col=P_type, ymin=prop.m-prop.se, ymax=prop.m+prop.se), inherit.aes=TRUE, width=0.1)
# 
# model2.long %>%
#   filter(ans==1 & bll==.1 & lf==.5, mas==2.8, ga==0.5) %>%
#   ggbarplot(x = 'P_type', y = 'prop.m',
#             label = TRUE, label.pos = "in",  lab.nb.digits = 2, lab.vjust = 5, size = 1,
#             col = 'P_type', palette = 'jco', position = position_dodge(0.8)) +
#   geom_errorbar(mapping=aes(x=P_type, col=P_type, ymin=prop.m-prop.se, ymax=prop.m+prop.se), inherit.aes=TRUE, width=0.1)
# 
# model3.long %>%
#   filter(alpha==.1 & egs==.01 & r1==0, r2==0) %>%
#   ggbarplot(x = 'P_type', y = 'prop.m',
#             label = TRUE, label.pos = "in",  lab.nb.digits = 2, lab.vjust = 5, size = 1,
#             col = 'P_type', palette = 'jco', position = position_dodge(0.8)) +
#   geom_errorbar(mapping=aes(x=P_type, col=P_type, ymin=prop.m-prop.se, ymax=prop.m+prop.se), inherit.aes=TRUE, width=0.1)
# 

#save.image("./shinyASP/ASP_model_data_full.RData")

# function: calculate BIC 
convert_bic <- function(k, n, logL) {
  return(k * log(n) - 2 * logL)
}

# function: concate all model outputs and individual data into one long-table
subj2model <- function(subj, model, k) {
  datalist = list()
  for (i in 1:nrow(model)) {
    model.r=model[i,]
    dat = subj2sim(subj, model.r, k)
    datalist[[i]] <- dat
  }
  result = data.frame(do.call(rbind, datalist))
  return(result)
}


subj2sim <- function(subj, model.r, k) {
  sim0 = subj %>%
    merge.data.frame(model.r) %>%
    mutate(AC.z=(AC-AC.m)/max(AC.sd, 1e-10),
           AI.z=(AI-AI.m)/max(AI.sd, 1e-10),
           PC.z=(PC-PC.m)/max(PC.sd, 1e-10),
           PI.z=(PI-PI.m)/max(PI.sd, 1e-10),
           AC.prob_z=dnorm(AC.z, 0, 1), 
           AI.prob_z=dnorm(AI.z, 0, 1),
           PC.prob_z=dnorm(PC.z, 0, 1),
           PI.prob_z=dnorm(PI.z, 0, 1),
           logL=log(AC.prob_z)+log(AI.prob_z)+log(PC.prob_z)+log(PI.prob_z),
           bic=convert_bic(k, n=4, logL))
  return(sim0)
}


#debug
datalist = list()
model1.r=model1[1,]
  dat = subj2sim(subj1, model1.r, 3) %>% select(subjID,AC, AC.m, AC.sd, AC.z, AC.prob_z, AI.prob_z, PC.prob_z, PI.prob_z, logL) %>% 
    #mutate(across(AC.prob_z:PI.prob_z, round, 6)) %>%
    View()

datalist[[i]] <- dat
result = data.frame(do.call(rbind, datalist))


# for exp1, each subj is fit into every possible model outputs
subj1model1  = subj2model(subj1, model1, 3) #70*150=10,500
subj1model2 = subj2model(subj1, model2, 5) #70*1440=100,800
subj1model3 = subj2model(subj=subj1, model=model3, k=4) #70*900=63,000

# find min bic, concat three models 
subj1models = subj1model1 %>% group_by(subjID) %>% slice(which.min(bic)) %>% select(subjID:mid, bic, logL, AC.m:PI.m) %>%
  full_join(subj1model2 %>% group_by(subjID) %>% slice(which.min(bic)) %>% select(subjID, mid, bic, logL, AC.m:PI.m), by = 'subjID', suffix=c('.m1', '.m2')) %>%
  full_join(subj1model3 %>% group_by(subjID) %>% slice(which.min(bic)) %>% select(subjID, mid, bic, logL, AC.m:PI.m) %>%
              setNames(c(names(.)[1], paste0(names(.)[-1],".m3"))) %>% 
              arrange(subjID), by = 'subjID') %>%
  ungroup(subjID)

# categorize best model
subj1_bestmodels = subj1models %>%
  rowwise() %>%
  mutate(min_bic = pmin(bic.m1, bic.m2, bic.m3)) %>%
  bind_cols(best_model = colnames(subj1models %>% select(starts_with("bic")))[apply(subj1models %>% select(starts_with("bic")),1,which.min)])


# pie plot of percentage of participants best fitted model
pie1 = subj1_bestmodels %>%
  group_by(best_model) %>% 
  summarise(n = n()) %>% mutate(freq = (round(n / sum(n), 4)), 
                                best_model = factor(gsub("min.", "", best_model))) %>% 
  arrange(desc(best_model)) %>%
  mutate(ypos = cumsum(freq) - 0.5*freq) %>%
  ggplot(aes(x="", y=freq, fill=best_model)) +
  geom_bar(stat="identity", width = 1, color="white") +
  geom_text(aes(y = ypos,label = paste0(freq*100, "%")), color = "white", size=8) +
  coord_polar("y", start = 0) +
  scale_fill_discrete(name = "Best fit model", labels = c("Declarative Model", "Spreading Model", "Reinforcement Model")) +
  ggtitle('Experiment 1: The percentage of subjects fit in model simulation output') +
  theme_void() +
  theme(legend.position = 'bottom')

pie1

# plot of individual pattern vs. model pattern
lnum=0
unum=10
subj1_bestmodels %>%
  select(subjID, bic.m1, bic.m2, bic.m3, min_bic, best_model, AC:PI, AC.m.m1:PI.m.m1, AC.m.m2:PI.m.m2, AC.m.m3:PI.m.m3) %>%
  gather('P_type', 'mean_prop', AC:PI.m.m3) %>%  
  mutate(P_type = str_replace(P_type, '.m', ''),
         #D_type = ifelse(str_detect(P_type, ".m"), "model", "subject"),
         D_type = case_when(str_detect(P_type, ".m1") ~ "m1", str_detect(P_type, ".m2") ~ "m2", str_detect(P_type, ".m3") ~ "m3", TRUE ~ "subject")) %>% 
  filter(subjID > lnum & subjID < unum) %>%
  ggbarplot(x = 'D_type', y = 'mean_prop', add = c(""), facet.by = 'subjID',
            col = c('P_type'), lab.size=3, position = position_dodge(0.8),
            label = TRUE, label.pos = "out",  lab.nb.digits = 2, lab.vjust = 2)  +
  geom_text(data=subj1_bestmodels %>% filter(subjID > lnum & subjID < unum), aes(x=1.8, y=1.1, label=paste0("fit bic = ", round(min_bic, 2))), 
            colour="black", inherit.aes=FALSE, parse=FALSE) +
  geom_text(data=subj1_bestmodels %>% filter(subjID > lnum & subjID < unum), aes(x=1.8, y=1.3, label=paste0("best model = ", best_model)), 
            colour="red", inherit.aes=FALSE, parse=FALSE) + 
  ggtitle("Exp1 subj vs. model with fit bic ")


# 6 subject plots
subj1_bestmodels.temp = subj1_bestmodels %>%  
  select(subjID, mid.m1, mid.m2, mid.m3, bic.m1, bic.m2, bic.m3, min_bic, best_model, AC:PI, AC.m.m1:PI.m.m1, AC.m.m2:PI.m.m2, AC.m.m3:PI.m.m3) %>%
  arrange(min_bic) %>%
  group_by(best_model) %>% slice(1:2)

ind.plot1 = subj1_bestmodels.temp %>%
  gather('P_type', 'mean_prop', AC:PI.m.m3) %>% 
  mutate(P_type = str_replace(P_type, '.m', ''),
         D_type = case_when(str_detect(P_type, ".m1") ~ "m1", str_detect(P_type, ".m2") ~ "m2", str_detect(P_type, ".m3") ~ "m3", TRUE ~ "subject"),
         P_type = case_when(str_detect(P_type, "AC") ~ "AC", str_detect(P_type, "AI") ~ "AI", str_detect(P_type, "PC") ~ "PC",  str_detect(P_type, "PI") ~ "PI", TRUE ~ "subject"),
         syn_voice = ifelse(P_type=="AC"|P_type=="AI", "Active", "Passive"),
         syn_corr = ifelse(P_type=="AC"|P_type=="PI", "Correct", "Incorrect")) %>% 
  ggplot(aes(x = syn_voice, y = mean_prop, group = interaction(syn_voice, syn_corr), col = syn_corr)) +
  geom_point(aes(shape = D_type), size = 5, position = position_dodge(width=0.75)) +
  scale_shape_manual(name="Model vs. Subject", values=c(0, 1, 2, 8)) +
  ggsci::scale_color_jco(name="Prime Condition: syntactic correctness") +
  geom_text(data=subj1_bestmodels.temp, aes(x=1.5, y=1.2, label=paste0("min bic: ", round(min_bic, 2))), 
            inherit.aes=FALSE, parse=FALSE) +
  geom_text(data=subj1_bestmodels.temp, aes(x=1.5, y=1.1, label=paste0("best fit model: ", str_replace(best_model, 'bic.', ''))), 
            inherit.aes=FALSE, parse=FALSE) +
  facet_grid(.~subjID) +
  ggtitle("Experiment 1: Individual differences of model fitting") + 
  labs(x = "Conditions", y = "Proportion of Actice descriptions") + 
  theme(legend.position = 'bottom')

ind.plot1
ggarrange(ind.plot1, pie1,
          labels = c("A", "B"),
          ncol = 2, nrow = 1)




  
# Exp 2~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

subj2model1 = subj2model(subj2, model1, 3) #141*150=21,150
subj2model2 = subj2model(subj2, model2, 5) #141*1440=203,040
subj2model3 = subj2model(subj=subj2, model=model3, k=4) #141*900=126,900


subj2models = subj2model1 %>% group_by(subjID) %>% slice(which.min(bic)) %>% select(subjID:mid, bic, logL, AC.m:PI.m) %>%
  full_join(subj2model2 %>% group_by(subjID) %>% slice(which.min(bic)) %>% select(subjID, mid, bic, logL, AC.m:PI.m), by = 'subjID', suffix=c('.m1', '.m2')) %>%
  full_join(subj2model3 %>% group_by(subjID) %>% slice(which.min(bic)) %>% select(subjID, mid, bic, logL, AC.m:PI.m) %>%
              setNames(c(names(.)[1], paste0(names(.)[-1],".m3"))) %>% 
              arrange(subjID), by = 'subjID') %>%
  ungroup(subjID)

subj2_bestmodels = subj2models %>%
  rowwise() %>%
  mutate(min_bic = pmin(bic.m1, bic.m2, bic.m3)) %>%
  bind_cols(best_model = colnames(subj2models %>% select(starts_with("bic")))[apply(subj2models %>% select(starts_with("bic")),1,which.min)])

subj2_bestmodels %>%
  tibble::rowid_to_column("subjID2") %>%
  filter(subjID2 < 49) %>%
  select(subjID2, min_bic, best_model) %>% 
  ggbarplot(x = 'subjID2', y = 'min_bic', fill='best_model', add = c(""), size = .5,
            position = position_dodge(0.8),
            label = TRUE, label.pos = "out",  lab.nb.digits = 2, lab.vjust = -1) + 
  ggtitle('Min BIC for each individual in Exp2')


# subj2 %>% select(subjID, AC, AI, PC, PI) %>%
#   tibble::rowid_to_column("subjID2") %>%
#   filter(subjID2 < 49) %>%
#   gather('P_type', 'mean_prop', AC:PI) %>%
#   ggbarplot(x = 'P_type', y = 'mean_prop', add = c(""), facet.by = 'subjID2',
#             color = "P_type", size = .5,
#             palette = 'jco', position = position_dodge(0.8),
#             label = TRUE, label.pos = "in",  lab.nb.digits = 2, lab.vjust = 0)


# plot of percentage of participants best fitted model
pie2 = subj2_bestmodels %>%
  group_by(best_model) %>% 
  summarise(n = n()) %>% mutate(freq = (round(n / sum(n), 4)), 
                                best_model = factor(gsub("min.", "", best_model))) %>% 
  arrange(desc(best_model)) %>%
  mutate(ypos = cumsum(freq) - 0.5*freq) %>%
  ggplot(aes(x="", y=freq, fill=best_model)) +
  geom_bar(stat="identity", width = 1, color="white") +
  geom_text(aes(y = ypos,label = paste0(freq*100, "%")), color = "white", size=8) +
  coord_polar("y", start = 0) +
  scale_fill_discrete(name = "Best fit model", labels = c("Declarative Model", "Spreading Model", "Reinforcement Model")) +
  ggtitle('Experiment 2: The percentage of subjects fit in model simulation output') +
  theme_void() + 
  theme(legend.position = "bottom")

pie2


# plot of individual pattern vs. model pattern
lnum=0
unum=10
subj2_bestmodels %>%
  tibble::rowid_to_column("subjID2") %>%
  select(subjID2, bic.m1, bic.m2, bic.m3, min_bic, best_model, AC:PI, AC.m.m1:PI.m.m1, AC.m.m2:PI.m.m2, AC.m.m3:PI.m.m3) %>%
  gather('P_type', 'mean_prop', AC:PI.m.m3) %>%  
  mutate(P_type = str_replace(P_type, '.m', ''),
         #D_type = ifelse(str_detect(P_type, ".m"), "model", "subject"),
         D_type = case_when(str_detect(P_type, ".m1") ~ "m1", str_detect(P_type, ".m2") ~ "m2", str_detect(P_type, ".m3") ~ "m3", TRUE ~ "subject")) %>% 
  filter(subjID2 > lnum & subjID2 < unum) %>%
  ggbarplot(x = 'D_type', y = 'mean_prop', add = c(""), facet.by = 'subjID2',
            col = c('P_type'), lab.size=3, position = position_dodge(0.8),
            label = FALSE, label.pos = "out",  lab.nb.digits = 2, lab.vjust = 2)  +
  geom_text(data=subj1_bestmodels %>% tibble::rowid_to_column("subjID2") %>% filter(subjID2 > lnum & subjID2 < unum), aes(x=1.8, y=1.1, label=paste0("fit bic = ", round(min_bic, 2))), 
            colour="black", inherit.aes=FALSE, parse=FALSE) +
  geom_text(data=subj1_bestmodels %>% tibble::rowid_to_column("subjID2") %>% filter(subjID2 > lnum & subjID2 < unum), aes(x=1.8, y=1.3, label=paste0("best model = ", best_model)), 
            colour="red", inherit.aes=FALSE, parse=FALSE) + 
  ggtitle("Exp2 subj vs. model with fit bic - 6")


# 6 subject plots
subj2_bestmodels.temp = subj2_bestmodels %>%
  tibble::rowid_to_column("subjID2") %>%
  select(subjID2, mid.m1, mid.m2, mid.m3, bic.m1, bic.m2, bic.m3, min_bic, best_model, AC:PI, AC.m.m1:PI.m.m1, AC.m.m2:PI.m.m2, AC.m.m3:PI.m.m3) %>%
  arrange(min_bic) %>%
  group_by(best_model) %>% slice(1:2)

ind.plot2 = subj2_bestmodels.temp %>%
  gather('P_type', 'mean_prop', AC:PI.m.m3) %>% 
  mutate(P_type = str_replace(P_type, '.m', ''),
         D_type = case_when(str_detect(P_type, ".m1") ~ "m1", str_detect(P_type, ".m2") ~ "m2", str_detect(P_type, ".m3") ~ "m3", TRUE ~ "subject"),
         P_type = case_when(str_detect(P_type, "AC") ~ "AC", str_detect(P_type, "AI") ~ "AI", str_detect(P_type, "PC") ~ "PC",  str_detect(P_type, "PI") ~ "PI", TRUE ~ "subject"),
         syn_voice = ifelse(P_type=="AC"|P_type=="AI", "DO", "PD"),
         syn_corr = ifelse(P_type=="AC"|P_type=="PI", "Correct", "Incorrect")) %>% 
  ggplot(aes(x = syn_voice, y = mean_prop, group = interaction(syn_voice, syn_corr), col = syn_corr)) +
  geom_point(aes(shape = D_type), size = 5, position = position_dodge(width=0.75)) +
  facet_grid(.~subjID2) +
  geom_text(data=subj2_bestmodels.temp, aes(x=1.5, y=1.2, label=paste0("min bic: ", round(min_bic, 2))), 
            inherit.aes=FALSE, parse=FALSE) +
  geom_text(data=subj2_bestmodels.temp, aes(x=1.5, y=1.1, label=paste0("best fit model: ", best_model)), 
            inherit.aes=FALSE, parse=FALSE) +
  ggtitle("Experiment 2: Individual differences of model fitting") + 
  labs(x = "Conditions", y = "Proportion of Actice descriptions") + 
  scale_shape_manual(name="Model vs. Subject", values=c(0, 1, 2, 8)) +
  ggsci::scale_color_jco(name="Prime Condition: syntactic correctness") +
  theme(legend.position = 'bottom')


ind.plot2
ggarrange(ind.plot1, ind.plot2,
          labels = c("A", "B"),
          ncol = 1, nrow = 2)



#subj2_bestmodels.temp %>% left_join(model1 %>% rename(mid.m1=mid) %>% select(mid.m1:lf), by='mid.m1') %>% write_csv(path = './temp1.csv')
#subj2_bestmodels.temp %>% left_join(model2 %>% rename(mid.m2=mid) %>% select(mid.m2:ga), by='mid.m2') %>% write_csv(path = './temp2.csv')
#subj2_bestmodels.temp %>% left_join(model3 %>% rename(mid.m3=mid) %>% select(mid.m3:r2), by='mid.m3') %>% write_csv(path = './temp3.csv')

# loglikelihood
subj1_bestmodels %>% select(logL.m1, logL.m2, logL.m3) %>%
  colSums()
subj2_bestmodels %>% select(logL.m1, logL.m2, logL.m3) %>%
  colSums()
s1m1.logL = -862.1803
s1m2.logL = -826.8703
s1m3.logL = -857.6427
LL1 <- c(s1m1.logL, s1m2.logL,s1m3.logL)
rLL1 <- LL1 - min(LL1)
rLL.dat1 <- data.frame(LL = LL1, rLL = rLL1,
                       dLL.nullm1 = c(s1m1.logL-s1m1.logL, s1m2.logL-s1m1.logL, s1m3.logL-s1m1.logL),
                       dLL.nullm2 = c(s1m1.logL-s1m2.logL, s1m2.logL-s1m2.logL, s1m3.logL-s1m2.logL),
                       dLL.nullm3 = c(s1m1.logL-s1m3.logL, s1m2.logL-s1m3.logL, s1m3.logL-s1m3.logL),
                       model=c("m1", "m2", "m3"), exp = "Exp1")
s2m1.logL = -1433.287
s2m2.logL = -1375.635
s2m3.logL = -1376.439
LL2 <- c(s2m1.logL, s2m2.logL,s2m3.logL)
rLL2 <- LL2 - min(LL2)
rLL.dat2 <- data.frame(LL = LL2, rLL = rLL2, 
                       dLL.nullm1 = c(s2m1.logL-s2m1.logL, s2m2.logL-s2m1.logL, s2m3.logL-s2m1.logL),
                       dLL.nullm2 = c(s2m1.logL-s2m2.logL, s2m2.logL-s2m2.logL, s2m3.logL-s2m2.logL),
                       dLL.nullm3 = c(s2m1.logL-s2m3.logL, s2m2.logL-s2m3.logL, s2m3.logL-s2m3.logL),
                       model=c("m1", "m2", "m3"), exp = "Exp2")
rLL.dat = rLL.dat1 %>% bind_rows(rLL.dat2) %>%
  mutate(bf1 = exp(dLL.nullm1), bf2 = exp(dLL.nullm2), bf3 = exp(dLL.nullm3)) %>%
  mutate(model=case_when(model=="m1"~"Declarative Model", model=="m2"~"Spreading Model", model=="m3"~"Reinforcement Model", TRUE~""))
  # mutate(p.bf1=case_when(bf1<3.2~"0", bf1>3.2 & bf1<10~"substantial", bf1>10 & bf1<100~"Strong", bf1>100~"Decisive", TRUE~"N/A"), 
  #        p.bf2=case_when(bf1<3.2~"0", bf1>3.2 & bf1<10~"substantial", bf1>10 & bf1<100~"Strong", bf1>100~"Decisive", TRUE~"N/A"), 
  #        p.bf3=case_when(bf1<3.2~"0", bf1>3.2 & bf1<10~"substantial", bf1>10 & bf1<100~"Strong", bf1>100~"Decisive", TRUE~"N/A")) %>%
  # mutate_if(is.numeric, round, 4)

rLL.plot1 <- ggbarplot(rLL.dat, x="model", y="rLL", fill="model", 
                       lab.nb.digits = 2, label = rLL.dat$rLL, lab.pos = "out",
                       facet.by = "exp") + ylim(0,80) + theme(legend.position="None") + 
  ggtitle("The relative log-likelihood of three models") +
  labs(y="relative log-likelihood") 

rLL.plot1

ggarrange(rLL.plot1, rLL.plot2, nrow = 1, common.legend = TRUE) 

########################### reward distribution
# rdiff.dat1 = subj1_bestmodels %>% 
#   filter(best_model=='bic.m3') %>%
#   select(subjID, mid.m1, mid.m2, mid.m3, bic.m1, bic.m2, bic.m3, min_bic, best_model, AC:PI, AC.m.m1:PI.m.m1, AC.m.m2:PI.m.m2, AC.m.m3:PI.m.m3) %>%
#   arrange(min_bic) %>%
#   left_join(model3 %>% rename(mid.m3=mid) %>% select(mid.m3:r2)) %>% 
#   mutate(exp = 'exp1', rdiff = r1-r2) %>% select(exp, rdiff)
# 
# # balance of rewards
# rdiff.dat2 = subj2_bestmodels %>% 
#   tibble::rowid_to_column("subjID2") %>%
#   filter(best_model=='bic.m3') %>%
#   select(subjID2, mid.m1, mid.m2, mid.m3, bic.m1, bic.m2, bic.m3, min_bic, best_model, AC:PI, AC.m.m1:PI.m.m1, AC.m.m2:PI.m.m2, AC.m.m3:PI.m.m3) %>%
#   arrange(min_bic) %>%
#   left_join(model3 %>% rename(mid.m3=mid) %>% select(mid.m3:r2)) %>% 
#   mutate(exp = 'exp2', rdiff = r1-r2) %>% select(exp, rdiff)
# 
# rdiff.dat1 %>% bind_rows(rdiff.dat2) %>%
#   gghistogram(x='rdiff', fill = 'exp', binwidth = .5, add = 'mean', alpha = .3)

#####################################

# bic.plot <- ggarrange(
#   gghistogram(subj1model1, x = "bic", color="#F8766D", bins = 100)+ 
#     ggtitle("Model1 fit Exp1", 
#             subtitle = paste0("min bic = ", round(min(subj1model1$bic),3))),
#   gghistogram(subj1model2, x = "bic", color="#00B81F", bins = 100)+ 
#     ggtitle("Model2 fit Exp1", 
#             subtitle = paste0("min bic = ", round(min(subj1model2$bic),3))), 
#   gghistogram(subj1model3, x = "bic", color="#00A5FF", bins = 100)+ 
#     ggtitle("Model3 fit Exp1",
#             subtitle = paste0("min bic = ", round(min(subj1model3$bic),3))),
#   gghistogram(subj2model1, x = "bic", color="#F8766D", bins = 100)+ 
#     ggtitle("Model1 fit Exp2",
#             subtitle = paste0("min bic = ", round(min(subj2model1$bic),3))),
#   gghistogram(subj2model2, x = "bic", color="#00B81F", bins = 100)+ 
#     ggtitle("Model2 fit Exp2",
#             subtitle = paste0("min bic = ", round(min(subj2model2$bic),3))),
#   gghistogram(subj2model3, x = "bic", color="#00A5FF", bins = 100)+ 
#     ggtitle("Model3 fit Exp2",
#             subtitle = paste0("min bic = ", round(min(subj2model3$bic),3))),
#   nrow = 2, ncol = 3
# )
# 


# subj1model1 %>% select(X1, bic) %>% mutate(model="m1") %>% 
#   bind_rows(subj1model2 %>% select(X1, bic) %>% mutate(model="m2")) %>%
#   bind_rows(subj1model3 %>% select(X1, bic) %>% mutate(model="m3")) %>%
#   ggdensity(x="bic", fill = "model",alpha = .2, facet.by = "model")


subj1models.histdat = subj1model1 %>% select(X1, bic) %>% mutate(model="m1") %>% 
  bind_rows(subj1model2 %>% select(X1, bic) %>% mutate(model="m2")) %>%
  bind_rows(subj1model3 %>% select(X1, bic) %>% mutate(model="m3")) %>%
  filter(bic<500) %>%
  mutate(model=factor(model))
  #mutate(model=factor(case_when(model=="m1" ~"Declarative model", model=="m2" ~"Spreading model",model=="m3" ~"Reinnforcement model", TRUE ~ "")))

subj2models.histdat = subj2model1 %>% select(X1, bic) %>% mutate(model="m1") %>% 
  bind_rows(subj2model2 %>% select(X1, bic) %>% mutate(model="m2")) %>%
  bind_rows(subj2model3 %>% select(X1, bic) %>% mutate(model="m3")) %>%
  filter(bic<500) %>%
  mutate(model=factor(model))
  #mutate(model=factor(case_when(model=="m1" ~"Declarative model", model=="m2" ~"Spreading model",model=="m3" ~"Reinnforcement model", TRUE ~ "")))

levels(subj1models.histdat$model) <- c("Declarative model","Spreading model", "Reinnforcement model")
levels(subj2models.histdat$model) <- c("Declarative model","Spreading model", "Reinnforcement model")


bic.histplot = ggarrange(
  subj1models.histdat %>% gghistogram(x = "bic", bins = 100, col = "model", fill = "model", alpha = .3) +
    ggtitle("Experiment1: BIC histogram of three models "),
  subj2models.histdat %>% gghistogram(x = "bic", bins = 100, col = "model", fill = "model", alpha = .3) +
    ggtitle("Experiment2: BIC histogram of three models "), 
  subj1models.histdat %>% ggdensity(x="bic", col = "model",  fill = "model", alpha = .3) + theme(legend.position = "none"),
  subj2models.histdat %>% ggdensity(x="bic", col = "model", fill = "model", alpha = .3) + theme(legend.position = "none"),
  common.legend = TRUE, legend = "bottom"
)

bic.histplot

subj1models.histdat %>% 
  arrange(bic) %>%
  group_by(model) %>% 
  slice(1) %>% 
  select(model, bic)

subj2models.histdat %>% 
  arrange(bic) %>%
  group_by(model) %>% 
  slice(1) %>% 
  select(model, bic)
