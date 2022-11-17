# One-sample Bootstrap 95% CI's
# Edie Espejo
# 2022-11-06
# 2022-11-17


library(arrow)
library(dplyr)
library(ggplot2)
library(knitr)
library(kableExtra)
library(readxl)
library(tidyr)

source('BootstrapStats-20220920.R')
source('stigmatizingLanguageFuncs.R')

# Data ------------------
boot_file <- 'C:/Users/eespejo/Box/IC Case Study - Julien Cobert/keyword_expansion/race_boot_patient_v2.parquet'
boot_data <- read_parquet(boot_file)

julien_class <- 'C:/Users/eespejo/Box/projects/stigmatizing-language/Edie class and subclasses.xls'
class_data   <- read_excel(julien_class) %>% select(class, base_word, subclass)

boot_data0 <- left_join(boot_data, class_data) %>%
  filter(class == 'stigmatizing') %>%
  rename(target_word = base_word) %>%
  filter(bootstrap == 0)

boot_data <- left_join(boot_data, class_data) %>%
  filter(class == 'stigmatizing') %>%
  rename(target_word = base_word) %>%
  filter(bootstrap != 0)

output_folder <- 'C:/Users/eespejo/Box/projects/stigmatizing-language/final-20221104/results-threeSample/'


# Bootstrap -------------
set.seed(42) # !!!!

boot_data0_long <- boot_data0 %>%
  reshape2::melt(id.vars=c('bootstrap', 'shuffle', 'class', 'subclass', 'target_word')) %>%
  rename(base_word=variable) %>%
  rename(cosine_distance=value)

boot_data_long <- boot_data %>%
  reshape2::melt(id.vars=c('bootstrap', 'shuffle', 'class', 'subclass', 'target_word')) %>%
  rename(base_word=variable) %>%
  rename(cosine_distance=value)

pwa_means      <- list()
pwa_tests      <- list()
pwa_diff_tests <- list()


## Violence -------------

### PWA Mean ------------ 
set.seed(42) # !!!!
pwa_means[['violence']] <- boot_data0_long %>%
  filter(subclass == 'violence') %>%
  pwa_mean()

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

### PWA Mean ------------ 
set.seed(42) # !!!!
pwa_means[['passivity']] <- boot_data0_long %>%
  filter(subclass == 'passivity') %>%
  pwa_mean()

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

### PWA Mean ------------ 
set.seed(42) # !!!!
pwa_means[['nonadherence']] <- boot_data0_long %>%
  filter(grepl('adher', target_word)) %>%
  pwa_mean()

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

### PWA Mean ------------ 
set.seed(42) # !!!!
pwa_means[['noncompliance']] <- boot_data0_long %>%
  filter(grepl('compli', target_word)) %>%
  pwa_mean()


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

### PWA Mean ------------ 
set.seed(42) # !!!!
pwa_means[['non_compli_adhere']] <- boot_data0_long %>%
  filter(grepl('compli|adher', target_word)) %>%
  pwa_mean()


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


### PWA Mean ------------ 
set.seed(42) # !!!!
pwa_means[['describe_patient']] <- boot_data0_long %>%
  filter(target_word %in% adjectives_for_patients) %>%
  pwa_mean()

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

## PWA Means ------------
all_pwa_means <- do.call(rbind, pwa_means)
all_pwa_means$theme <- row.names(all_pwa_means)

## PWA Tests ------------
all_pwa_tests <- do.call(rbind, pwa_tests)
all_pwa_tests$theme <- row.names(all_pwa_tests)

midpoints <- lapply(1:length(pwa_tests), function(i) {
  theme <- names(pwa_tests)[i]
  
  j <- gsub('\\(|\\)|\\*', '', pwa_tests[[i]])
  k <- lapply(strsplit(j, ','), as.numeric)
  m <- sapply(k, mean)
  names(m) <- names(pwa_tests[[1]])
  
  c(theme=theme, m)
})

midpoints_df <- data.frame(do.call(rbind, midpoints))


### Combine PWA tests and means.
three_sample_results <- left_join(all_pwa_means %>%
                                  pivot_longer(!theme, names_to='base', values_to='mean'),
                                  all_pwa_tests %>%
                                  pivot_longer(!theme, names_to='base', values_to='ci')) %>%
  left_join(midpoints_df %>%
              pivot_longer(!theme, names_to='base', values_to='midpt')) %>%
  pivot_wider(names_from=theme, values_from=c(mean, ci, midpt))
three_sample_save <- three_sample_results[,c(1,2,8,14,3,9,15,4,10,16,5,11,17,
                                             6,12,18,7,13,19)]

write.csv(all_pwa_tests,
          paste0(output_folder, 'CI-pwaOneSample95.csv'))

## Difference Tests -----
all_pwa_diff_tests <- do.call(rbind, pwa_diff_tests)
write.csv(all_pwa_diff_tests,
          paste0(output_folder, 'CI-pwaDifferences95FW.csv'))
