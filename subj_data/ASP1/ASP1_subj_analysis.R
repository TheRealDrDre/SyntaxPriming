#~~~~~~~~~~~~~~~~~~~~~~~~~~~
# This script analyze ASP1 subj data


library(tidyverse) # handy utility functions
library(dplyr)
library(ggpubr)
library(lme4)
rm(list = ls())

data_raw <- read_csv("./ASP1_double_checked.csv")

# pre-processinng raw data
data_dirty <- data_raw %>%
  mutate(syn_voice = factor(ifelse(P_type=="AC"|P_type=="AI", "A", "P")), 
         syn_corr = factor(ifelse(P_type=="AC"|P_type=="PC", "C", "I")),
         subjID = factor(subjID),
         P_type = factor(P_type)) %>%
  select(-Trial, -error_type_old, -error_type, -message) %>%
  na.omit(isactive)
summary(data_dirty)

# look at indiviudal performance
subj_summary = data_dirty %>% group_by(subjID) %>% summarise(resp_accuracy=mean(resp_iscorrect), mean_prop=mean(isactive), missing_entries=36-n())

#data_dirty <- data_dirty %>% filter(resp_iscorrect==TRUE) # only look at response corr trials


# missing too many entries
bad_subj1 <- subj_summary %>% filter(missing_entries > 4)

# no priming effects
#bad_subj2 <- subj_summary %>% filter(mean_prop>.9 | mean_prop<0.1) 
bad_subj2 <- subj_summary %>% filter(mean_prop==1 | mean_prop==0)

# low resp_accuracy
bad_subj3 <- subj_summary %>% filter(resp_accuracy<.6)

data_clean <- data_dirty %>% 
  anti_join(bad_subj1) %>%   #remove 199 entries(16 subj)
  anti_join(bad_subj2)%>%
  anti_join(bad_subj3)


# data summary
data_clean %>%
  group_by(P_type, syn_voice, syn_corr) %>%
  summarise(prop_isactive = mean(isactive))

data_dirty %>%
  group_by(P_type, syn_voice, syn_corr) %>%
  summarise(prop_isactive = mean(isactive, na.rm=TRUE))

# calculate the p(DO)
df_prop <- data_dirty %>%
  group_by(subjID, P_type, syn_voice, syn_corr) %>%
  summarise(prop_isactive = mean(isactive))

# transformation (does not work ;(
logitTransform <- function(p) { log((p+.001)/(1-p+.001)) }
asinTransform <- function(p) { asin(sqrt(p)) }
#df_prop <- df_prop %>% mutate(prop_isactive=asinTransform(prop_isactive))
  

# DO vs. P : p<.01***
effect1 <- df_prop %>% group_by(subjID, syn_voice) %>%
  summarise(prop_isactive = mean(prop_isactive)) %>%
  spread(syn_voice, prop_isactive)
wilcox.test(effect1$A, effect1$P , paired = TRUE, alternative = "two.sided")
t.test(effect1$A, effect1$P , paired = TRUE, alternative = "two.sided")

# C vs. I: p>.1
effect2 <- df_prop %>% group_by(subjID, syn_corr) %>%
  summarise(prop_isactive = mean(prop_isactive)) %>%
  spread(syn_corr, prop_isactive)
wilcox.test(effect2$C, effect2$I, paired = TRUE, alternative = "two.sided")
t.test(effect2$C, effect2$I, paired = TRUE, alternative = "two.sided")

# AC vs. AI p>.1
effect3 <- df_prop %>% 
  filter(syn_voice=='A') %>%
  group_by(subjID, syn_corr) %>%
  summarise(prop_isactive = mean(prop_isactive)) %>%
  spread(syn_corr, prop_isactive)
wilcox.test(effect3$C, effect3$I, paired = TRUE, alternative = "two.sided")
t.test(effect3$C, effect3$I, paired = TRUE, alternative = "two.sided")

# P C vs. P I p = 0.08962 * 0.0791
effect4 <- df_prop %>% 
  filter(syn_voice=='P') %>%
  group_by(subjID, syn_corr) %>%
  summarise(prop_isactive = mean(prop_isactive)) %>%
  spread(syn_corr, prop_isactive)
wilcox.test(effect4$C, effect4$I, paired = TRUE, alternative = "two.sided") 
t.test(effect4$C, effect4$I, paired = TRUE, alternative = "two.sided")


### multi-level regression
summary(m1 <- lmer(isactive ~ 1 + syn_voice + (1|subjID), data=data_clean))
summary(m2 <- lmer(isactive ~ 1 + syn_voice + syn_corr + (1|subjID), data=data_clean))
anova(m1, m2)  #p > .1

summary(m3 <- lmer(isactive ~ 1 + (1|subjID), data=data_clean %>% filter(syn_voice=="A")))
summary(m4 <- lmer(isactive ~ 1 + syn_corr + (1|subjID), data=data_clean %>% filter(syn_voice=="A")))
anova(m3, m4) #p > .1

summary(m5 <- lmer(isactive ~ 1 + (1|subjID), data=data_clean %>% filter(syn_voice=="P ")))
summary(m6 <- lmer(isactive ~ 1 + syn_corr + (1|subjID), data=data_clean %>% filter(syn_voice=="P ")))
anova(m5, m6) #p > .1

#~~~ proportion data
summary(m1.1 <- lmer(prop_isactive ~ 1 + syn_voice + (1|subjID), data=df_prop))
summary(m2.1 <- lmer(prop_isactive ~ 1 + syn_voice + syn_corr + (1|subjID), data=df_prop))
anova(m1.1, m2.1)  #p > .1

summary(m3.1 <- lmer(prop_isactive ~ 1 + (1|subjID), data=df_prop %>% filter(syn_voice=="A")))
summary(m4.1 <- lmer(prop_isactive ~ 1 + syn_corr + (1|subjID), data=df_prop %>% filter(syn_voice=="A")))
anova(m3.1, m4.1) #p > .1

summary(m5.1 <- lmer(prop_isactive ~ 1 + (1|subjID), data=df_prop %>% filter(syn_voice=="P")))
summary(m6.1 <- lmer(prop_isactive ~ 1 + syn_corr + (1|subjID), data=df_prop %>% filter(syn_voice=="P")))
anova(m5.1, m6.1) #p > 0.08719 *
 


### plot main effect
plot <- df_prop %>%
  group_by(syn_voice, syn_corr, P_type) %>%
  get_summary_stats(prop_isactive, type = "mean_se") %>%
  ggplot(aes(x=P_type, y=mean, group=syn_voice, fill=syn_voice)) + 
  geom_col(stat = "identity", position='dodge',width = .7, colour="black",
           fill=c("white","white", "gray","gray")) + 
  geom_text(aes(label = round(mean,2)), position = position_dodge(.5),  vjust = 5) +
  geom_errorbar(aes(ymin = mean-se, 
                    ymax = mean+se), 
                width=0.1, 
                position=position_dodge(.9)) +
  ylim(c(0,1)) + 
  ylab('Proportion of DO descriptions') +
  ggtitle('DO/PO Priming effect by Syntactic correctness and Syntactic voice') + 
  labs(x = "(DO vs. PO) x (Correct vs. Incorrect) \n Prime Conditions") +
  scale_fill_manual(values=c("white", "white", "gray", "gray"))

### plot
plot

####################################################################

# export wide format
subj1_wide = 
  #data_raw %>% 
  data_dirty %>%
  group_by(subjID, P_type) %>% 
  summarise(prop_isactive=mean(isactive, na.rm=TRUE)) %>% 
  spread(P_type, prop_isactive) 


subj1_wide = subj1_wide %>%
  bind_cols(subj_summary) %>%
  select(-subjID1)


#write_csv(subj1_wide, "/Users/cheryang/Documents/Code/ACT-R_PyProjects/ASP/subj_data/ASP1/ASP1_subj_wide.csv")
