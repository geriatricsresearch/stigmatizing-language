# Edie Espejo
# 2023-02-02

setwd('C:/Users/eespejo/Box/IC Case Study - Julien Cobert/edie/stigmatizing-language/cosine-similarities-mimic')
output_folder <- 'results - meanDifferences/'

library(arrow)
library(dplyr)
library(ggplot2)
library(knitr)
library(kableExtra)
library(readxl)
library(tidyr)

source('scripts/bootstrapFunctions.R')

# Data ------------------
boot_file <- 'C:/Users/eespejo/Box/IC Case Study - Julien Cobert/edie/stigmatizing-language/m3_bootstraps.parquet'
boot_data <- read_parquet(boot_file)

original_file <- 'C:/Users/eespejo/Box/IC Case Study - Julien Cobert/edie/stigmatizing-language/m3_original.parquet'
original_data <- read_parquet(original_file)

julien_class <- 'Edie class and subclasses.xls'
class_data   <- read_excel(julien_class) %>% select(class, base_word, subclass)

boot_data0 <- left_join(original_data, class_data) %>%
  filter(class == 'stigmatizing') %>%
  rename(target_word = base_word)

boot_data <- left_join(boot_data, class_data) %>%
  filter(class == 'stigmatizing') %>%
  rename(target_word = base_word)






# Bootstrap -------------

original_differences <- boot_data0 %>%
  group_by(target_word) %>%
  mutate(ac=african_american-caucasian) %>%
  mutate(ah=african_american-hispanic) %>%
  mutate(ch=caucasian-hispanic) %>%
  
  summarize(ac=mean(ac),
            ah=mean(ah),
            ch=mean(ch)) %>%
  
  pivot_longer(names_to='comparison', values_to='mean_difference', c(ac, ah, ch))


set.seed(42) # !!!!
bootstrap_se <- boot_data %>%
  group_by(target_word, bootstrap) %>%
  mutate(ac=african_american-caucasian) %>%
  mutate(ah=african_american-hispanic) %>%
  mutate(ch=caucasian-hispanic) %>%
  
  summarize(ac=mean(ac),
            ah=mean(ah),
            ch=mean(ch)) %>%
  
  ungroup() %>%
  group_by(target_word) %>%
  summarize_at(.vars=c('ac', 'ah', 'ch'),
               .funs=bootstrap_se) %>%
  
  pivot_longer(names_to='comparison', values_to='bootstrap_se', c(ac, ah, ch))


differences_ci <- left_join(original_differences, bootstrap_se) %>%
  mutate(bootstrap_me=qnorm(1-(0.05/3))*bootstrap_se) %>%
  mutate(lb=mean_difference-bootstrap_me) %>%
  mutate(ub=mean_difference+bootstrap_me) %>%
  mutate(significant=ifelse(lb<=0 & 0<=ub, 0, 1))  # No changes here, but in meanCIs.R changed 1->0. These are difference so remain 0.


write.csv(differences_ci,
          paste0(output_folder, 'CI-meanDifferences95FW.csv'))
