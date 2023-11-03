# Edie Espejo
# 2023-02-02

setwd('C:/Users/eespejo/Box/IC Case Study - Julien Cobert/edie/stigmatizing-language/rando-similiarities/')
pwa_folder     <- 'results - pwa/'
pwadiff_folder <- 'results - pwaDifferences/'


library(arrow)
library(dplyr)
library(ggplot2)
library(knitr)
library(kableExtra)
library(readxl)
library(tidyr)

source('scripts/bootstrapFunctions.R')

# Data ------------------
boot_file <- 'C:/Users/eespejo/Box/IC Case Study - Julien Cobert/edie/stigmatizing-language/rando/ucsf_bootstraps_rando.parquet_fixed'
boot_data <- read_parquet(boot_file)

original_file <- 'C:/Users/eespejo/Box/IC Case Study - Julien Cobert/edie/stigmatizing-language/rando/ucsf_original_rando.parquet_fixed'
original_data <- read_parquet(original_file)

julien_class <- 'Edie class and subclasses.xls'
class_data   <- read_excel(julien_class) %>% select(class, base_word, subclass)

boot_data0 <- left_join(original_data, class_data) %>%
  filter(class == 'rando') %>%
  rename(target_word = base_word)

boot_data <- left_join(boot_data, class_data) %>%
  filter(class == 'rando') %>%
  rename(target_word = base_word)






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

pwa_ci      <- list()
pwa_diff_ci <- list()


## Functions ------------

calculate_pwa <- function(cosine_distance_long) {
  cosine_distance_long %>%
    group_by(bootstrap, target_word, base_word) %>%
    
    summarize(cdk = mean(cosine_distance),
              sdk = sd(cosine_distance),
              ak  = 1/sdk^2) %>%
    ungroup() %>%
    group_by(bootstrap, base_word) %>%
    
    mutate(ak_cdk = cdk * ak) %>%
    summarize(theta_k = sum(ak_cdk, na.rm=TRUE) / sum(ak, na.rm=TRUE)) %>%
    
    ungroup() %>%
    reshape2::dcast(bootstrap ~ base_word, value.var='theta_k') %>%
    
    summarize_at(.vars=c('african_american', 'caucasian', 'hispanic'),
                 .funs=mean)
}

bootstrap_pwa_se <- function(cosine_distance_long) {
  set.seed(42) # !!!
  cosine_distance_long %>%
    group_by(bootstrap, target_word, base_word) %>%
    
    summarize(cdk = mean(cosine_distance),
              sdk = sd(cosine_distance),
              ak  = 1/sdk^2) %>%
    ungroup() %>%
    group_by(bootstrap, base_word) %>%
    
    mutate(ak_cdk = cdk * ak) %>%
    summarize(theta_k = sum(ak_cdk, na.rm=TRUE) / sum(ak, na.rm=TRUE)) %>%
    
    ungroup() %>%
    reshape2::dcast(bootstrap ~ base_word, value.var='theta_k') %>%
    
    summarize_at(.vars=c('african_american', 'caucasian', 'hispanic'),
                 .funs=bootstrap_se)
}

genPWAtable <- function(original_pwa, bootstrap_pwa_se) {
  pwa_df <- data.frame(t(rbind(names(original_pwa), original_pwa, bootstrap_pwa_se)))
  names(pwa_df) <- c('base_word', 'pwa', 'bootstrap_se')
  pwa_df <- tibble(pwa_df) %>%
    mutate(pwa=as.numeric(pwa)) %>%
    mutate(bootstrap_se=as.numeric(bootstrap_se))
  
  pwa_results <- pwa_df %>%
    mutate(bootstrap_me=qnorm(0.975)*bootstrap_se) %>%
    mutate(lb=pwa-bootstrap_me) %>%
    mutate(ub=pwa+bootstrap_me) %>%
    mutate(significant=ifelse(lb<=0 & 0<=ub, 0, 1)) %>% # Changed this from lb<=1 --> lb<=0. %>%
    mutate(pvalue=2*(1-pnorm(abs(pwa)/bootstrap_se)))
  
  return(pwa_results)
}



calculate_pwa_diff <- function(cosine_distance_long) {
  cosine_distance_long %>%
    group_by(bootstrap, target_word, base_word) %>%
    
    summarize(cdk = mean(cosine_distance),
              sdk = sd(cosine_distance),
              ak  = 1/sdk^2) %>%
    
    ungroup() %>%
    group_by(bootstrap, base_word) %>%
    
    mutate(ak_cdk = cdk * ak) %>%
    summarize(theta_k = sum(ak_cdk, na.rm=TRUE) / sum(ak, na.rm=TRUE)) %>%
    
    ungroup() %>%
    reshape2::dcast(bootstrap ~ base_word, value.var='theta_k') %>%
    
    mutate(ac=african_american-caucasian) %>%
    mutate(ah=african_american-hispanic) %>%
    mutate(ch=caucasian-hispanic)  %>%
    
    select(ac, ah, ch)
}

bootstrap_pwa_diff_se <- function(cosine_distance_long) {
  set.seed(42) # !!!
  cosine_distance_long %>%
    group_by(bootstrap, target_word, base_word) %>%
    
    summarize(cdk = mean(cosine_distance),
              sdk = sd(cosine_distance),
              ak  = 1/sdk^2) %>%
    
    ungroup() %>%
    group_by(bootstrap, base_word) %>%
    
    mutate(ak_cdk = cdk * ak) %>%
    summarize(theta_k = sum(ak_cdk, na.rm=TRUE) / sum(ak, na.rm=TRUE)) %>%
    
    ungroup() %>%
    reshape2::dcast(bootstrap ~ base_word, value.var='theta_k') %>%
    
    mutate(ac=african_american-caucasian) %>%
    mutate(ah=african_american-hispanic) %>%
    mutate(ch=caucasian-hispanic)  %>%
    
    select(ac, ah, ch) %>%
    
    summarize_at(.vars=c('ac', 'ah', 'ch'),
                 .funs=bootstrap_se)
}

genPWAdifftable <- function(original_pwa_diff, bootstrap_pwa_diff_se, multiplier=qnorm(0.975)) {
  pwa_diff_df <- data.frame(t(rbind(names(original_pwa_diff), original_pwa_diff, bootstrap_pwa_diff_se)))
  names(pwa_diff_df) <- c('comparison', 'pwa_difference', 'bootstrap_se')
  pwa_diff_df <- tibble(pwa_diff_df) %>%
    mutate(pwa_difference=as.numeric(pwa_difference)) %>%
    mutate(bootstrap_se=as.numeric(bootstrap_se))
  
  pwa_diff_results <- pwa_diff_df %>%
    mutate(bootstrap_me=multiplier*bootstrap_se) %>%
    mutate(lb=pwa_difference-bootstrap_me) %>%
    mutate(ub=pwa_difference+bootstrap_me) %>%
    mutate(significant=ifelse(lb<=0 & 0<=ub, 0, 1)) %>%
    mutate(pvalue=2*(1-pnorm(abs(pwa_difference)/bootstrap_se)))
  
  return(pwa_diff_results)
}


pwa_plot <- function(ci_data) {
  ci_data %>%
    ggplot(aes(color = base_word)) +
    geom_hline(yintercept=0, lwd=2, alpha=0.5) + # Changed yintercept=1 --> 0.
    geom_linerange(aes(x = base_word, ymin = lb, ymax = ub),
                   size=2, alpha=0.7, position = position_dodge(width=0.6)) +
    geom_point(aes(x=base_word, y=pwa),
               pch=15, position = position_dodge(width=0.6)) +
    
    scale_x_discrete(limits = rev) +
    coord_flip() +
    
    # Remove extraneous labels
    ylab('') +
    xlab('') +
    
    # Fix Legend
    scale_color_manual(name='Base word',
                       labels=c('African-American', 'Caucasian', 'Hispanic'),
                       values=c( '#61B329', '#1874CD',  '#FFC125')) +
    theme_bw()
  
}


doPWA <- function(filtered_data0, filtered_data) {
  original_pwa  <- filtered_data0 %>% calculate_pwa()
  bootstrap_pwa <- filtered_data %>% bootstrap_pwa_se()
  
  genPWAtable(original_pwa, bootstrap_pwa)
  
}

doPWAdiff <- function(filtered_data0, filtered_data) {
  original_pwa_diff  <- filtered_data0 %>% calculate_pwa_diff()
  bootstrap_pwa_diff <- filtered_data %>% bootstrap_pwa_diff_se()
  
  genPWAdifftable(original_pwa_diff, bootstrap_pwa_diff, multiplier=qnorm(1-(0.05/3)))
}


# Violence -------------
pwa_ci[['rando']] <- doPWA(boot_data0_long %>% filter(class == 'rando'),
                              boot_data_long %>% filter(class == 'rando'))

pwa_diff_ci[['rando']] <- doPWAdiff(boot_data0_long %>% filter(class == 'rando'),
                                       boot_data_long %>% filter(class == 'rando'))

pwa_ci[['rando']] %>% pwa_plot()
ggsave(paste0(pwa_folder, 'plot-rando.png'), width=10, height=7)  






# Save Results --------------

pwa_ci_list <- lapply(1:length(pwa_ci), function(k) pwa_ci[[k]] %>% mutate(theme=names(pwa_ci)[k]))
pwa_ci_df   <- do.call(rbind, pwa_ci_list) %>%
  select(theme, base_word, pwa, bootstrap_se, bootstrap_me, lb, ub, significant, pvalue) %>%
  mutate(pvalue=ifelse(pvalue>1, 1, pvalue))

write.csv(pwa_ci_df, paste0(pwa_folder, 'CI-pwa95.csv'))


pwa_diff_ci_list <- lapply(1:length(pwa_diff_ci), function(k) pwa_diff_ci[[k]] %>% mutate(theme=names(pwa_diff_ci)[k]))
pwa_diff_ci_df   <- do.call(rbind, pwa_diff_ci_list) %>%
  mutate(comparison=case_when(
    comparison == 'ac' ~ 'A-C',
    comparison == 'ah' ~ 'A-H',
    comparison == 'ch' ~ 'C-H',
    TRUE ~ as.character(NA)
  )) %>%
  select(theme, comparison, pwa_difference, bootstrap_se, bootstrap_me, lb, ub, significant, pvalue) %>%
  mutate(pvalue=ifelse(pvalue>1, 1, pvalue))

write.csv(pwa_diff_ci_df, paste0(pwadiff_folder, 'CI-pwaDiff95FW.csv'))
