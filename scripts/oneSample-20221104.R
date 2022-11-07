# One-sample Bootstrap 95% CI's
# Edie Espejo
# 2022-11-04


library(arrow)
library(dplyr)
library(ggplot2)
library(knitr)
library(kableExtra)
library(readxl)
library(tidyr)

source('BootstrapStats-20220920.R')

# Data ------------------
boot_file <- 'C:/Users/eespejo/Box/IC Case Study - Julien Cobert/keyword_expansion/race_boot_patient_v2.parquet'
boot_data <- read_parquet(boot_file)

julien_class <- 'C:/Users/eespejo/Box/projects/stigmatizing-language/Edie class and subclasses.xls'
class_data   <- read_excel(julien_class) %>% select(class, base_word, subclass)

boot_data <- left_join(boot_data, class_data) %>%
  filter(class == 'stigmatizing') %>%
  rename(target_word = base_word)

output_folder <- 'C:/Users/eespejo/Box/projects/stigmatizing-language/final-20221104/results-oneSample/'



# Bootstrap -------------
set.seed(42) # !!!!
one_sample_tests <- boot_data %>%
  group_by(target_word, bootstrap) %>%
  summarize_at(.vars=c('african_american', 'caucasian', 'hispanic'),
               .funs=mean) %>%
  summarize_at(.vars=c('african_american', 'caucasian', 'hispanic'),
               .funs=make_ci)

write.csv(one_sample_tests, paste0(output_folder, 'CI-oneSample95.csv'))



# Plots -----------------

## Plottable data
set.seed(42) # !!!!
one_sample_tests_plottable_0 <- boot_data %>%
  group_by(target_word, bootstrap) %>%
  summarize_at(.vars=c('african_american', 'caucasian', 'hispanic'),
               .funs=mean) %>%
  summarize_at(.vars=c('african_american', 'caucasian', 'hispanic'),
               .funs=~make_ci(., print_format=FALSE)) %>%
  mutate(attr=rep(c('lb', 'ub', 'significance')))

one_sample_tests_plottable <- one_sample_tests_plottable_0 %>%
  reshape2::melt(id.vars=c('attr', 'target_word')) %>%
  rename(base_word=variable) %>%
  rename(cosine_distance=value) %>%
  reshape2::dcast(base_word + target_word ~ attr, value.var='cosine_distance') %>%
  mutate(avg = (lb + ub)/2) %>%
  mutate(se=(ub-avg)/1.96) %>%
  mutate(lb_se = avg - se) %>%
  mutate(ub_se = avg + se) %>%
  mutate(base_word=factor(base_word, levels=c('african_american', 'caucasian', 'hispanic')))


## Stigmatizing Language
one_sample_tests_plottable %>%
  ggplot(aes(x=avg, y=target_word, group=target_word, color=base_word)) +
  geom_vline(xintercept = 1, lwd=1.5, alpha=0.8) +
  geom_segment(aes(y=target_word, yend=target_word, x=lb_se, xend=ub_se), lwd=1.5, alpha=0.4) +
  geom_point(aes(x=avg, y=target_word), pch=15, alpha=0.8) +
  # Colors per base
  scale_color_manual(name='Base word',
                     labels=c('African-American', 'Caucasian', 'Hispanic'),
                     values=c( '#61B329', '#1874CD',  '#FFC125')) +
  theme_bw() +
  # Remove extraneous labels
  ylab('') +
  xlab('')
  
ggsave(filename=paste0(output_folder, 'plot-stigmatizing.png'), width=7, height=5)


## Violence
one_sample_tests_plottable %>%
  left_join(boot_data %>% select(target_word, subclass) %>% distinct()) %>%
  filter(subclass == 'violence') %>%
  ggplot(aes( color = base_word)) +
  geom_hline(yintercept=1, lwd=1, alpha=0.5) +
  geom_linerange(aes(x = target_word, ymin = lb, ymax = ub),
                 size=2, alpha=0.7, position = position_dodge(width=0.6)) +
  geom_point(aes(x=target_word, y=avg),
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

ggsave(filename=paste0(output_folder, 'plot-violence.png'), width=7, height=5)


## Passivity
one_sample_tests_plottable %>%
  left_join(boot_data %>% select(target_word, subclass) %>% distinct()) %>%
  filter(subclass == 'passivity') %>%
  ggplot(aes(x=avg, y=target_word, group=target_word, color=base_word)) +
  geom_vline(xintercept = 1, lwd=1.5, alpha=0.8) +
  geom_segment(aes(y=target_word, yend=target_word, x=lb_, xend=ub), lwd=1.5, alpha=0.4) +
  geom_point(aes(x=avg, y=target_word), pch=15, alpha=0.8) +
  theme_bw() +
  # Remove extraneous labels
  ylab('') +
  xlab('') +
  # Fix Legend
  scale_color_manual(name='Base word',
                     labels=c('African-American', 'Caucasian', 'Hispanic'),
                     values=c( '#61B329', '#1874CD',  '#FFC125'))

ggsave(filename=paste0(output_folder, 'plot-passivity.png'), width=7, height=5)


## Non-adherence
one_sample_tests_plottable %>%
  filter(grepl('adher', target_word)) %>%
  ggplot(aes(x=avg, y=target_word, group=target_word, color=base_word)) +
  geom_vline(xintercept = 1, lwd=1.5, alpha=0.8) +
  geom_segment(aes(y=target_word, yend=target_word, x=lb, xend=ub), lwd=1.5, alpha=0.4) +
  geom_point(aes(x=avg, y=target_word), pch=15, alpha=0.8) +
  theme_bw() +
  # Remove extraneous labels
  ylab('') +
  xlab('') +
  # Fix Legend
  scale_color_manual(name='Base word',
                     labels=c('African-American', 'Caucasian', 'Hispanic'),
                     values=c( '#61B329', '#1874CD',  '#FFC125'))

ggsave(filename=paste0(output_folder, 'plot-nonadherence.png'), width=7, height=5)


## Non-compliance
one_sample_tests_plottable %>%
  filter(grepl('compli', target_word)) %>%
  mutate(base_word=factor(base_word, levels=c('african_american', 'caucasian', 'hispanic'))) %>%
  ggplot(aes(x=avg, y=target_word, group=target_word, color=base_word)) +
  geom_vline(xintercept = 1, lwd=1.5, alpha=0.8) +
  geom_segment(aes(y=target_word, yend=target_word, x=lb, xend=ub), lwd=1.5, alpha=0.4) +
  geom_point(aes(x=avg, y=target_word), pch=15, alpha=0.8) +
  theme_bw() +
  # Remove extraneous labels
  ylab('') +
  xlab('') +
  # Fix Legend
  scale_color_manual(name='Base word',
                     labels=c('African-American', 'Caucasian', 'Hispanic'),
                     values=c( '#61B329', '#1874CD',  '#FFC125'))
ggsave(filename=paste0(output_folder, 'plot-noncompliance.png'), width=7, height=5)