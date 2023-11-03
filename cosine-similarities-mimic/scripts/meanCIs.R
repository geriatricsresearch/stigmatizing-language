# Edie Espejo
# 2023-02-02

setwd('C:/Users/eespejo/Box/IC Case Study - Julien Cobert/edie/stigmatizing-language/cosine-similarities-mimic')
output_folder <- 'results - means/'


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




# Quantify Missing Data ------------
totals <- boot_data %>% group_by(target_word) %>% count()

missing_a <- boot_data %>%
  filter(is.na(african_american)) %>%
  group_by(target_word) %>%
  count() %>%
  rename(african_american=n)

missing_c <- boot_data %>%
  filter(is.na(caucasian)) %>%
  group_by(target_word) %>%
  count() %>%
  rename(caucasian=n)

missing_h <- boot_data %>%
  filter(is.na(hispanic)) %>%
  group_by(target_word) %>%
  count() %>%
  rename(hispanic=n)

missing_tbl <- left_join(totals, missing_a) %>%
  left_join(missing_c) %>%
  left_join(missing_h) %>%
  mutate_at(.vars=c('african_american', 'caucasian', 'hispanic'),
            .funs=~(ifelse(is.na(.), 0, .))) %>%
  mutate_at(.vars=c('african_american', 'caucasian', 'hispanic'),
            .funs=~./n * 100 %>% round(2))
write.csv(missing_tbl, 'results - missingData/missing-tbl-full.csv')


missing_tbl_sub <- missing_tbl %>% filter(african_american>0 | caucasian>0 | hispanic>0)
write.csv(missing_tbl_sub, 'results - missingData/missing-tbl-sub.csv')



# Mean Bootstrap -------------
set.seed(42) # !!!!
original_means <- boot_data0 %>%
  group_by(target_word) %>%
  summarize_at(.vars=c('african_american', 'caucasian', 'hispanic'),
               .funs=~mean(., na.rm=TRUE)) %>%
  pivot_longer(names_to='base_word', values_to='mean', cols=c(african_american, caucasian, hispanic))

  
set.seed(42) # !!!!
bootstrap_se <- boot_data %>%
  group_by(target_word, bootstrap) %>%
  summarize_at(.vars=c('african_american', 'caucasian', 'hispanic'),
               .funs=mean) %>%
  summarize_at(.vars=c('african_american', 'caucasian', 'hispanic'),
               .funs=bootstrap_se) %>%
  pivot_longer(names_to='base_word', values_to='bootstrap_se', cols=c(african_american, caucasian, hispanic))


# bootstrap_ci <- left_join(original_means, bootstrap_se) %>%
#   mutate(bootstrap_me=qnorm(0.975)*bootstrap_se) %>%
#   mutate(lb=mean-bootstrap_me) %>%
#   mutate(ub=mean+bootstrap_me) %>%
#   mutate(significant=ifelse(lb<=0 & 0<=ub, 0, 1))

bootstrap_ci <- left_join(original_means, bootstrap_se) %>%
  mutate(bootstrap_me=qnorm(0.975)*bootstrap_se) %>%
  mutate(lb=mean-bootstrap_me) %>%
  mutate(ub=mean+bootstrap_me) %>%
  mutate(significant=ifelse(lb<=0 & 0<=ub, 0, 1)) %>%
  mutate(pvalue=2*(1-pnorm(abs(mean)/bootstrap_se))) %>%
  mutate(pvalue=ifelse(pvalue>1, 1, pvalue))
  

write.csv(bootstrap_ci, paste0(output_folder, 'CI-means95.csv'))



# Plots V1 -----------------

## Stigmatizing Language
# bootstrap_ci %>%
#   filter(!target_word %in% missing_tbl_sub$target_word) %>%
#   simple_plot()
# ggsave(filename=paste0(output_folder, 'plot-stigmatizing.png'), width=7, height=5)


## Violence
# bootstrap_ci %>%
#   left_join(boot_data %>% select(target_word, subclass) %>% distinct()) %>%
#   filter(subclass == 'violence') %>%
#   simple_plot()
# ggsave(filename=paste0(output_folder, 'plot-violence.png'), width=7, height=5)


## Passivity
# bootstrap_ci %>%
#   left_join(boot_data %>% select(target_word, subclass) %>% distinct()) %>%
#   filter(subclass == 'passivity') %>%
#   simple_plot()
# ggsave(filename=paste0(output_folder, 'plot-passivity.png'), width=7, height=5)


## Non-adherence
# bootstrap_ci %>% filter(grepl('adher', target_word)) %>% simple_plot()
# ggsave(filename=paste0(output_folder, 'plot-nonadherence.png'), width=7, height=5)


## Non-compliance
# bootstrap_ci %>%
#   filter(grepl('compli', target_word)) %>%
#   mutate(base_word=factor(base_word, levels=c('african_american', 'caucasian', 'hispanic'))) %>%
#   simple_plot()
# ggsave(filename=paste0(output_folder, 'plot-noncompliance.png'), width=7, height=5)


# Plots V2 -----------------
facetgrid_plot <- function(bootstrap_data) {
  p <- bootstrap_data %>%
    
    # Set the canvas
    ggplot(aes(y=base_word, x=mean, group=base_word)) +
    
    # Add the centers
    geom_point(pch=15, col='black', alpha=0.7) +
    
    # Draw the CI's
    geom_segment(aes(y=base_word, yend=base_word, x=lb, xend=ub, col=base_word), lwd=2, alpha=0.7) +
    scale_color_manual(name='Base word',
                       labels=c('African-American', 'Caucasian', 'Hispanic'),
                       values=c('#55AE3A', '#00868B', '#FFC125')) + 
    
    # Separate based on the targets
    facet_grid(target_word ~ ., switch='both') +
    
    # Design choices
    theme_bw() +
    theme(strip.text.y.left=element_text(angle=0),
          axis.text.y=element_blank(),
          axis.ticks.y=element_blank()) +
    
    # Remove extraneous labels
    ylab('') +
    xlab('')
  
  return(p)
}


# All words as requested by Julien.
bootstrap_ci0 <- left_join(bootstrap_ci, class_data %>% rename(target_word=base_word))
bootstrap_ci0 %>% facetgrid_plot()
ggsave(filename=paste0(output_folder, 'facetgrid-stigmatizing0.png'), width=7, height=10)




# bootstrap_ci <- left_join(bootstrap_ci, class_data %>% rename(target_word=base_word)) %>%
#   filter(!target_word %in% missing_tbl_sub$target_word)

bootstrap_ci <- left_join(bootstrap_ci, class_data %>% rename(target_word=base_word))

# Plot the Bonferroni-correct CI's
bootstrap_ci %>% facetgrid_plot()
ggsave(filename=paste0(output_folder, 'facetgrid-stigmatizing.png'), width=7, height=10)

bootstrap_ci %>% filter(subclass == 'violence') %>% facetgrid_plot()
ggsave(filename=paste0(output_folder, 'facetgrid-violence.png'), width=7, height=10)

bootstrap_ci %>% filter(subclass == 'passivity') %>% facetgrid_plot()
ggsave(filename=paste0(output_folder, 'facetgrid-passivity.png'), width=7, height=10)

bootstrap_ci %>% filter(grepl('adher', target_word)) %>% facetgrid_plot()
ggsave(filename=paste0(output_folder, 'facetgrid-nonadherence.png'), width=7, height=10)

bootstrap_ci %>% filter(grepl('compli', target_word)) %>% facetgrid_plot()
ggsave(filename=paste0(output_folder, 'facetgrid-noncompliance.png'), width=7, height=10)
