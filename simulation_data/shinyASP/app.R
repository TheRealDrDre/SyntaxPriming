#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)
library(shinyWidgets)
library(ggpubr)
rm(list = ls())

# data loading
load("./ASP_model_data_full.RData")
load("./ASP_image.RData")

# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
   titlePanel("ASP MODEL"),
   
   helpText("Create plot with information from model simulation"),
     
   # Show a plot 
   mainPanel(tabsetPanel(id = "tabset", type = "tabs",
                 tabPanel("Summary", value = "panel0", plotOutput("plot.model0", height = 1000)),
                 tabPanel("Model1", value = "panel1", 
                          fluidRow(
                            column(width = 4, shinyWidgets::sliderTextInput("m1.ans", label = ":ans", animate=TRUE, choices = c(0.1, 0.25, 0.5, 0.75, 1, 1.5))), 
                            column(width = 4, sliderInput("m1.bll", ":bll", animate=TRUE, min = .1, max = .9, value = .1, step = .2)),
                            column(width = 4, sliderInput("m1.lf", ":lf", animate=TRUE, min = .1, max = .9, value = .1, step = .2)),
                            column(width = 12, plotOutput("plot.model1")
                                   ))),
                 tabPanel("Model2", value = "panel2", 
                          fluidRow(
                            column(width = 4, shinyWidgets::sliderTextInput("m2.ans", label = ":ans", animate=TRUE, choices = c(0.1, 0.25, 0.5, 0.75, 1, 1.5))), 
                            column(width = 4, shinyWidgets::sliderTextInput("m2.bll", label = ":bll", animate=TRUE, choices = c(0.1, 0.3, 0.5, 0.7, 0.9))),
                            column(width = 4, shinyWidgets::sliderTextInput("m2.lf", label = ":lf", animate=TRUE, choices = c(0.5, 0.7, 0.9, 1))),
                            column(width = 4, sliderInput("m2.ga", ":ga",animate=TRUE, min = .5, max = 2, value = .5, step = .5)),
                            column(width = 4, sliderInput("m2.mas", ":mas",animate=TRUE, min = 2.8, max = 3.6, value = 2.8, step = .4)),
                            column(width = 12, plotOutput("plot.model2")
                            ))),
                 tabPanel("Model3", value = "panel3", 
                          fluidRow(
                            column(width = 4, shinyWidgets::sliderTextInput("m3.egs", label = ":egs", choices = c(0.01, 0.1, 0.5, 0.9, 1.3))),
                            column(width = 4, sliderInput("m3.alpha", ":alpha", animate=TRUE, min = .1, max = .9, value = .1, step = .2)),
                            column(width = 4, shinyWidgets::sliderTextInput("m3.r1", label = ":R+", choices = c(0, 0.1, 0.5, 1, 5, 10))),
                            column(width = 4, shinyWidgets::sliderTextInput("m3.r2", label = ":R-", choices = c(-10, -5, -1, -0.5, -0.1, 0))),
                            column(width = 12, plotOutput("plot.model3")
                            ))),
                 tabPanel("Exp1: Individual fitting", value = "panel4", 
                          fluidRow(
                            numericRangeInput(inputId = "m4.subjID", label = "Exp1: SubjID", value = c(1, 14), separator = " to "),
                            column(width = 12, plotOutput("plot.model4")
                            ))), 
                 tabPanel("Exp2: Individual fitting", value = "panel5", 
                          fluidRow(
                            numericRangeInput(inputId = "m5.subjID", label = "Exp2: SubjID", value = c(1, 14), separator = " to "),
                            column(width = 12, plotOutput("plot.model5")
                            ))),
                 tabPanel("Exps Data", 
                          fluidRow(
                            helpText("Experiment 1"),
                            column(width = 12, dataTableOutput('table.subj1bestmodels')),
                            helpText("Experiment 2"),
                            column(width = 12, dataTableOutput('table.subj2bestmodels')),
                            helpText("m1 = Declarative Model; m2 = Spreading Model; m3 = Reinforcement Model"),
                            helpText("suffix '.m.m1' indicates model simulation output")
                            )), 
                 tabPanel("Models Data", 
                          fluidRow(
                            helpText("Model 1"),
                            column(width = 12, dataTableOutput('table.model1')),
                            helpText("Model 2"),
                            column(width = 12, dataTableOutput('table.model2')),
                            helpText("Model 3"),
                            column(width = 12, dataTableOutput('table.model3'))
                            ))
                 ) # end tabsetPanel
             ) # end mainPanel
   ) # end fluidPage
     
# Define server logic required to draw a histogram
server <- function(input, output) {
  output$plot.model0 <- renderPlot({
    subj1.plot = subj1 %>%
      select(AC, AI, PC, PI) %>%
      gather(key = "P_type", value = prop_isa, AC:PI) %>%
      group_by(P_type) %>%
      get_summary_stats(type = 'mean_se') %>%
      select(P_type, mean, se) %>% 
      mutate(data_type = 'Exp1')%>%
      ggbarplot(x = 'P_type', y = 'mean', fill = 'P_type', palette = 'jco', 
                position = position_dodge(0.8)) + 
      ggtitle("Exp1 Subject Data") + 
      labs(x="", y="mean proportion of producing Active constructions") +
      ylim(0,1)
    subj2.plot = subj2 %>%
      select(AC, AI, PC, PI) %>%
      gather(key = "P_type", value = prop_isa, AC:PI) %>%
      group_by(P_type) %>%
      get_summary_stats(type = 'mean_se') %>%
      select(P_type, mean, se) %>% 
      mutate(P_type = case_when(P_type=="AC"~"DOC", P_type=="AI"~"DOI", P_type=="PC"~"DPC", P_type=="PI"~"DPI", TRUE~""),
             data_type = 'Exp2') %>%
      ggbarplot(x = 'P_type', y = 'mean', fill = 'P_type', palette = 'jco', 
                position = position_dodge(0.8)) + 
      labs(x="", y="mean proportion of producing DO constructions") +
      ggtitle("Exp2 Subject Data") +
      ylim(0,1)
  
    m.plot = model1 %>% select(AC.m:PI.m) %>% mutate(model="m1") %>%
      rbind(model2 %>% select(AC.m:PI.m) %>% mutate(model="m2")) %>%
      rbind(model3 %>% select(AC.m:PI.m) %>% mutate(model="m3")) %>% 
      gather("P_type", "mean_prop", AC.m:PI.m) %>%
      group_by(model, P_type) %>%
      get_summary_stats(type = 'mean_se') %>%
      select(model, P_type, mean, se) %>% 
      ggbarplot(x = 'P_type', y = 'mean', fill = 'P_type',
                palette = 'jco', facet.by = "model",
                position = position_dodge(0.8)) + 
      ggtitle("Model Simulation Data") + 
      labs(x="", y="mean proportion of producing syntactic structure") +
      ylim(0,1)
    
    
    subj.plot <- ggarrange(ggarrange(subj1.plot, subj2.plot, ncol = 2),m.plot, nrow = 2)
    subj.plot
  })
  
  output$plot.model1 <- renderPlot({
    model1.long %>%
      filter(ans==input$m1.ans & bll==input$m1.bll & lf==input$m1.lf) %>% 
      ggbarplot(x = 'P_type', y = 'prop.m',
                label = TRUE, label.pos = "in",  lab.nb.digits = 2, lab.vjust = 5, size = 1,
                col = 'P_type', palette = 'jco', position = position_dodge(0.8)) +
      geom_errorbar(mapping=aes(x=P_type, col=P_type, ymin=prop.m-prop.se, ymax=prop.m+prop.se), inherit.aes=TRUE, width=0.1) +
      labs(title = "Model1: Mean and SE of simulation outputs", 
           x="Prime conditions: Active vs. Passive, Correct vs. Incorrect", 
           y="Proportion of producing Active constructions") + ylim(0,1)
  })
  
  output$plot.model2 <- renderPlot({
    model2.long %>%
      filter(ans==input$m2.ans & bll==input$m2.bll & lf==input$m2.lf & ga==input$m2.ga, mas==input$m2.mas) %>% 
      ggbarplot(x = 'P_type', y = 'prop.m',
                label = TRUE, label.pos = "in",  lab.nb.digits = 2, lab.vjust = 5, size = 1,
                col = 'P_type', palette = 'jco', position = position_dodge(0.8)) +
      geom_errorbar(mapping=aes(x=P_type, col=P_type, ymin=prop.m-prop.se, ymax=prop.m+prop.se), inherit.aes=TRUE, width=0.1) +
      labs(title = "Model2: Mean and SE of simulation outputs", 
           x="Prime conditions: Active vs. Passive, Correct vs. Incorrect", 
           y="Proportion of producing Active constructions") + ylim(0,1)
  })
  
  output$plot.model3 <- renderPlot({
    
    model3.long %>%
      filter(egs==input$m3.egs & alpha==input$m3.alpha & r1==input$m3.r1 & r2==input$m3.r2) %>% 
      ggbarplot(x = 'P_type', y = 'prop.m',
                label = TRUE, label.pos = "in",  lab.nb.digits = 2, lab.vjust = 5, size = 1,
                col = 'P_type', palette = 'jco', position = position_dodge(0.8)) +
      geom_errorbar(mapping=aes(x=P_type, col=P_type, ymin=prop.m-prop.se, ymax=prop.m+prop.se), inherit.aes=TRUE, width=0.1) +
      labs(title = "Model3: Mean and SE of simulation outputs", 
           x="Prime conditions: Active vs. Passive, Correct vs. Incorrect", 
           y="Proportion of producing Active constructions") + ylim(0,1)

  })
  
  output$plot.model4 <- renderPlot({
    subj1_bestmodels.temp = subj1_bestmodels %>%  ungroup() %>%
      #filter(subjID>=1 & subjID<=6) %>%
      filter(subjID>=input$m4.subjID[1] & subjID<=input$m4.subjID[2]) %>%
      select(subjID, mid.m1, mid.m2, mid.m3, bic.m1, bic.m2, bic.m3, min_bic, best_model, AC:PI, AC.m.m1:PI.m.m1, AC.m.m2:PI.m.m2, AC.m.m3:PI.m.m3)

    subj1_bestmodels.temp %>%
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
      facet_wrap(~subjID, ncol=5) +
      ggtitle("Experiment 1: Individual differences of model fitting") + 
      labs(x = "Conditions", y = "Proportion of Actice descriptions") + 
      theme(legend.position = 'bottom')
  }, height = 1000)
  
  output$plot.model5 <- renderPlot({
    subj2_bestmodels.temp = subj2_bestmodels %>%
      tibble::rowid_to_column("subjID2") %>%
      filter(subjID2>=input$m5.subjID[1] & subjID2<=input$m5.subjID[2]) %>%
      select(subjID2, mid.m1, mid.m2, mid.m3, bic.m1, bic.m2, bic.m3, min_bic, best_model, AC:PI, AC.m.m1:PI.m.m1, AC.m.m2:PI.m.m2, AC.m.m3:PI.m.m3) %>%
      arrange(min_bic) %>%
      group_by(best_model) %>% slice(1:2)
    
    subj2_bestmodels.temp %>%
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
  }, height = 1000)
  
  output$table.subj1bestmodels <- renderDataTable(subj1_bestmodels)
  
  output$table.subj2bestmodels <- renderDataTable(subj2_bestmodels %>% tibble::rowid_to_column("subjID2"))
  
  output$table.model1 <- renderDataTable(model1)
  output$table.model2 <- renderDataTable(model2)
  output$table.model3 <- renderDataTable(model3)
}  

# Run the application 
shinyApp(ui = ui, server = server)

