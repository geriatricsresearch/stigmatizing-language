# One-sample Bootstrap 95% CI's
# Edie Espejo
# 2022-11-06


library(arrow)
library(dplyr)
library(ggplot2)
library(knitr)
library(kableExtra)
library(readxl)
library(tidyr)

source('BootstrapStats-20220920.R')
source('stigmatizingLangTests.R')

# Data ------------------
boot_file <- 'C:/Users/eespejo/Box/IC Case Study - Julien Cobert/keyword_expansion/race_boot_patient_v2.parquet'
boot_data <- read_parquet(boot_file)

julien_class <- 'C:/Users/eespejo/Box/projects/stigmatizing-language/Edie class and subclasses.xls'
class_data   <- read_excel(julien_class) %>% select(class, base_word, subclass)

boot_data <- left_join(boot_data, class_data) %>%
  filter(class == 'stigmatizing') %>%
  rename(target_word = base_word)


output_folder <- 'C:/Users/eespejo/Box/projects/stigmatizing-language/final-20221104/results-threeSample/'


# Bootstrap -------------
set.seed(42) # !!!!
boot_data_long <- boot_data %>%
  reshape2::melt(id.vars=c('bootstrap', 'shuffle', 'class', 'subclass', 'target_word')) %>%
  rename(base_word=variable) %>%
  rename(cosine_distance=value)

pwa_tests      <- list()
pwa_diff_tests <- list()


## Violence -------------

### PWA Test ------------ 
set.seed(42) # !!!!
pwa_tests[['violence']] <- boot_data_long %>%
  filter(subclass == 'violence') %>%
  pwa_test()

### Difference Test -----
set.seed(42) # !!!!
pwa_diff_tests[['violence']] <- boot_data_long %>%
  filter(subclass == 'violence') %>%
  pwa_diff_test()

### Plot -------
set.seed(42) # !!!!
boot_data_long %>%
  filter(subclass == 'violence') %>%
  pwa_plot()
ggsave(paste0(output_folder, 'plot-violence.png'),
       width=10, height=7)


## Passivity ------------

### PWA Test ------------
set.seed(42) # !!!!
pwa_tests[['passivity']] <- boot_data_long %>%
  filter(subclass == 'passivity') %>%
  pwa_test()

### Difference Test -----
set.seed(42) # !!!!
pwa_diff_tests[['passivity']] <- boot_data_long %>%
  filter(subclass == 'passivity') %>%
  pwa_diff_test()

### Plot -------
set.seed(42) # !!!!
boot_data_long %>%
  filter(subclass == 'passivity') %>%
  pwa_plot()
ggsave(paste0(output_folder, 'plot-passivity.png'),
       width=10, height=7)



## Non-adherence --------

### PWA Test ------------
set.seed(42) # !!!!
pwa_tests[['nonadherence']] <- boot_data_long %>%
  filter(grepl('adher', target_word)) %>%
  pwa_test()

### Difference Test -----
set.seed(42) # !!!!
pwa_diff_tests[['nonadherence']] <- boot_data_long %>%
  filter(grepl('adher', target_word)) %>%
  pwa_diff_test()

### Plot -------
set.seed(42) # !!!!
boot_data_long %>%
  filter(grepl('adher', target_word)) %>%
  pwa_plot()
ggsave(paste0(output_folder, 'plot-nonadherence.png'),
       width=10, height=7)




## Non-compliance -------

### PWA Test ------------
set.seed(42) # !!!!
pwa_tests[['noncompliance']] <- boot_data_long %>%
  filter(grepl('compli', target_word)) %>%
  pwa_test()

### Difference Test -----
set.seed(42) # !!!!
pwa_diff_tests[['noncompliance']] <- boot_data_long %>%
  filter(grepl('compli', target_word)) %>%
  pwa_diff_test()

### Plot -------
set.seed(42) # !!!!
boot_data_long %>%
  filter(grepl('compli', target_word)) %>%
  pwa_plot()
ggsave(paste0(output_folder, 'plot-noncompliance.png'),
       width=10, height=7)



## Non-compliance/adherence -------

### PWA Test ------------
set.seed(42) # !!!!
pwa_tests[['non_compli_adhere']] <- boot_data_long %>%
  filter(grepl('compli|adher', target_word)) %>%
  pwa_test()

### Difference Test -----
set.seed(42) # !!!!
pwa_diff_tests[['non_compli_adhere']] <- boot_data_long %>%
  filter(grepl('compli|adher', target_word)) %>%
  pwa_diff_test()

### Plot -------
set.seed(42) # !!!!
boot_data_long %>%
  filter(grepl('compli|adher', target_word)) %>%
  pwa_plot()
ggsave(paste0(output_folder, 'plot-noncompliadhere.png'),
       width=10, height=7)



## Words to Describe Patient -------
adjectives_for_patients <- c('noncooperative', 'nonadherent', 'non_adherence', 'non_adherent', 'nonadherence',
                             'noncompliance', 'non_compliant', 'non_compliance', 'noncompliant', 'anger', 'angrily',
                             'combative', 'confront', 'unpleasant', 'agitation')


### PWA Test ------------
set.seed(42) # !!!!
pwa_tests[['describe_patient']] <- boot_data_long %>%
  filter(target_word %in% adjectives_for_patients) %>%
  pwa_test()

### Difference Test -----
set.seed(42) # !!!!
pwa_diff_tests[['describe_patient']] <- boot_data_long %>%
  filter(target_word %in% adjectives_for_patients) %>%
  pwa_diff_test()

### Plot -------
set.seed(42) # !!!!
boot_data_long %>%
  filter(target_word %in% adjectives_for_patients) %>%
  pwa_plot()
ggsave(paste0(output_folder, 'plot-describepatient.png'),
       width=10, height=7)


# Save Tests ------------

## PWA Tests ------------
all_pwa_tests <- do.call(rbind, pwa_tests)
write.csv(all_pwa_tests,
          paste0(output_folder, 'CI-pwaOneSample95.csv'))

## Difference Tests -----
all_pwa_diff_tests <- do.call(rbind, pwa_diff_tests)
write.csv(all_pwa_diff_tests,
          paste0(output_folder, 'CI-pwaDifferences95FW.csv'))
