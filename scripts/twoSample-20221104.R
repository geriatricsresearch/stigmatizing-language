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


output_folder <- 'C:/Users/eespejo/Box/projects/stigmatizing-language/final-20221104/results-twoSample/'



# Bootstrap -------------
set.seed(42) # !!!!
two_sample_tests <- boot_data %>%
  
  group_by(target_word, bootstrap) %>%
  mutate(ac=african_american-caucasian) %>%
  mutate(ah=african_american-hispanic) %>%
  mutate(ch=caucasian-hispanic) %>%
  
  summarize(mean_ac=mean(ac),
            mean_ah=mean(ah),
            mean_ch=mean(ch)) %>%
  
  summarize(ci_ac=make_ci(mean_ac, ci_width=2.13, test_value=0),
            ci_ah=make_ci(mean_ah, ci_width=2.13, test_value=0),
            ci_ch=make_ci(mean_ch, ci_width=2.13, test_value=0))

write.csv(two_sample_tests,
          paste0(output_folder, 'CI-twoSample95FW.csv'))





# Plots -----------------

## Two-sample dataset for significance
set.seed(42) # !!!!
two_sample_tests0 <- boot_data %>%
  
  group_by(target_word, bootstrap) %>%
  mutate(ac=african_american-caucasian) %>%
  mutate(ah=african_american-hispanic) %>%
  mutate(ch=caucasian-hispanic) %>%
  
  summarize(mean_ac=mean(ac),
            mean_ah=mean(ah),
            mean_ch=mean(ch)) %>%
  
  summarize(ci_ac=make_ci(mean_ac, ci_width=2.13, test_value=0, print_format=FALSE),
            ci_ah=make_ci(mean_ah, ci_width=2.13, test_value=0, print_format=FALSE),
            ci_ch=make_ci(mean_ch, ci_width=2.13, test_value=0, print_format=FALSE)) %>%
  
  mutate(attr=rep(c('lb', 'ub', 'significance')))

significance_df <- bind_rows(two_sample_tests0 %>%
                               select(target_word, ci_ac, attr) %>%
                               rename(value=ci_ac) %>%
                               mutate(comparison='A-C'),
                             two_sample_tests0 %>%
                               select(target_word, ci_ah, attr) %>%
                               rename(value=ci_ah) %>%
                               mutate(comparison='A-H'),
                             two_sample_tests0 %>%
                               select(target_word, ci_ch, attr) %>%
                               rename(value=ci_ch) %>%
                               mutate(comparison='C-H'))

significance_df <- significance_df %>%
  filter(attr == 'lb') %>%
  rename(lb=value) %>%
  select(-attr) %>%
  left_join(significance_df %>%
              filter(attr == 'ub') %>%
              rename(ub=value) %>%
              select(-attr)) %>%
  left_join(significance_df %>%
              filter(attr == 'significance') %>% 
              rename(significance=value) %>% 
              select(-attr)) %>%
  mutate(avg=(lb+ub)/2)

## One-sample tests for the CI's
set.seed(42) # !!!!
one_sample_tests <- boot_data %>%
  group_by(target_word, bootstrap) %>%
  summarize_at(.vars=c('african_american', 'caucasian', 'hispanic'),
               .funs=mean) %>%
  summarize_at(.vars=c('african_american', 'caucasian', 'hispanic'),
               .funs=~make_ci(., print_format=FALSE)) %>%
  mutate(attr=rep(c('lb', 'ub', 'significance')))

plottable_df <- bind_rows(one_sample_tests %>%
                            select(target_word, african_american, attr) %>%
                            rename(value=african_american) %>%
                            mutate(base_word='african_american'),
                          one_sample_tests %>%
                            select(target_word, caucasian, attr) %>%
                            rename(value=caucasian) %>%
                            mutate(base_word='caucasian'),
                          one_sample_tests %>%
                            select(target_word, hispanic, attr) %>%
                            rename(value=hispanic) %>%
                            mutate(base_word='hispanic'))

plottable_df <- plottable_df %>% filter(attr == 'lb') %>% rename(lb=value) %>% select(-attr) %>%
  left_join(plottable_df %>% filter(attr == 'ub') %>% rename(ub=value) %>% select(-attr)) %>%
  left_join(plottable_df %>% filter(attr == 'significance') %>% rename(significance=value) %>% select(-attr)) %>%
  mutate(avg=(lb+ub)/2) %>%
  mutate(base_word=factor(base_word, levels=c('african_american', 'caucasian', 'hispanic')))


## Stigmatizing Language
# Choose terms
this_plot_df <- plottable_df

# Create "any" signficance variable among the tests
this_plot_color <- significance_df %>%
  mutate(significance=as.factor(significance)) %>%
  group_by(target_word) %>%
  summarize(anySig=any(significance==1)) %>%
  right_join(this_plot_df)

# Plot the Bonferroni-correct CI's
this_plot_df %>%
  
  # Set the canvas
  ggplot(aes(y=base_word, x=avg, group=base_word)) +
  
  # Set background for signficant comparisons
  geom_rect(data=subset(this_plot_color, anySig==1),
            aes(fill=anySig), xmin=-Inf, xmax=Inf, ymin=-Inf, ymax=Inf, show.legend=FALSE) +
  scale_fill_manual(values=c('#FFF8DC')) + 
  
  # Draw the CI's
  geom_segment(data=this_plot_df, aes(y=base_word, yend=base_word, x=lb, xend=ub, col=base_word), lwd=2) +
  scale_color_manual(name='Base word',
                     labels=c('African-American', 'Caucasian', 'Hispanic'),
                     values=c('#55AE3A', '#00868B', '#FFC125')) + 
  
  # Add the centers
  geom_point(pch=15, col='black', alpha=0.7) +
  
  # Separate based on the targets
  facet_grid(target_word ~ ., switch='both') +
  
  # Design choices
  theme_bw() +
  theme(strip.text.y.left=element_text(angle=0),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  
  # Remove extraneous labels
  ylab('') +
  xlab('')

ggsave(filename=paste0(output_folder, 'plot-stigmatizing.png'), width=7, height=10)


## Violence
# Choose terms
this_plot_df <- plottable_df %>%
  left_join(boot_data %>%
              select(target_word, subclass)) %>%
  filter(subclass=='violence')

# Create "any" signficance variable among the tests
this_plot_color <- significance_df %>%
  mutate(significance=as.factor(significance)) %>%
  group_by(target_word) %>%
  summarize(anySig=any(significance==1)) %>%
  right_join(this_plot_df)

# Plot the Bonferroni-correct CI's
this_plot_df %>%
  
  # Set the canvas
  ggplot(aes(y=base_word, x=avg, group=base_word)) +
  
  # Set background for signficant comparisons
  geom_rect(data=subset(this_plot_color, anySig==1),
            aes(fill=anySig), xmin=-Inf, xmax=Inf, ymin=-Inf, ymax=Inf, show.legend=FALSE) +
  scale_fill_manual(values=c('#FFF8DC')) + 
  
  # Draw the CI's
  geom_segment(data=this_plot_df, aes(y=base_word, yend=base_word, x=lb, xend=ub, col=base_word), lwd=2) +
  scale_color_manual(name='Base word',
                     labels=c('African-American', 'Caucasian', 'Hispanic'),
                     values=c('#55AE3A', '#00868B', '#FFC125')) + 
  
  # Add the centers
  geom_point(pch=15, col='black', alpha=0.7) +
  
  # Separate based on the targets
  facet_grid(target_word ~ ., switch='both') +
  
  # Design choices
  theme_bw() +
  theme(strip.text.y.left=element_text(angle=0),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  
  # Remove extraneous labels
  ylab('') +
  xlab('')

ggsave(filename=paste0(output_folder, 'plot-violence.png'), width=7, height=10)


## Passivity
# Choose terms
this_plot_df <- plottable_df %>%
  left_join(boot_data %>%
              select(target_word, subclass)) %>%
  filter(subclass=='passivity')

# Create "any" signficance variable among the tests
this_plot_color <- significance_df %>%
  mutate(significance=as.factor(significance)) %>%
  group_by(target_word) %>%
  summarize(anySig=any(significance==1)) %>%
  right_join(this_plot_df)

# Plot the Bonferroni-correct CI's
this_plot_df %>%
  
  # Set the canvas
  ggplot(aes(y=base_word, x=avg, group=base_word)) +
  
  # Set background for signficant comparisons
  geom_rect(data=subset(this_plot_color, anySig==1),
            aes(fill=anySig), xmin=-Inf, xmax=Inf, ymin=-Inf, ymax=Inf, show.legend=FALSE) +
  scale_fill_manual(values=c('#FFF8DC')) + 
  
  # Draw the CI's
  geom_segment(data=this_plot_df, aes(y=base_word, yend=base_word, x=lb, xend=ub, col=base_word), lwd=2) +
  scale_color_manual(name='Base word',
                     labels=c('African-American', 'Caucasian', 'Hispanic'),
                     values=c('#55AE3A', '#00868B', '#FFC125')) + 
  
  # Add the centers
  geom_point(pch=15, col='black', alpha=0.7) +
  
  # Separate based on the targets
  facet_grid(target_word ~ ., switch='both') +
  
  # Design choices
  theme_bw() +
  theme(strip.text.y.left=element_text(angle=0),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  
  # Remove extraneous labels
  ylab('') +
  xlab('')

ggsave(filename=paste0(output_folder, 'plot-passivity.png'), width=7, height=10)


## Non-adherence
# Choose "non-adherence" terms
this_plot_df <- plottable_df %>% filter(grepl('adher', target_word))

# Create "any" signficance variable among the tests
this_plot_color <- significance_df %>%
  mutate(significance=as.factor(significance)) %>%
  group_by(target_word) %>%
  summarize(anySig=any(significance==1)) %>%
  right_join(this_plot_df)

# Plot the Bonferroni-correct CI's
this_plot_df %>%
  
  # Set the canvas
  ggplot(aes(y=base_word, x=avg, group=base_word)) +
  
  # Set background for signficant comparisons
  geom_rect(data=subset(this_plot_color, anySig==1),
            aes(fill=anySig), xmin=-Inf, xmax=Inf, ymin=-Inf, ymax=Inf) +
  scale_fill_manual(values=c('#FFF8DC')) + 
  
  # Draw the CI's
  geom_segment(data=this_plot_df, aes(y=base_word, yend=base_word, x=lb, xend=ub, col=base_word), lwd=2) +
  scale_color_manual(values=c('#55AE3A', '#00868B', '#FFC125')) + 
  
  # Add the centers
  geom_point(pch=15, col='black', alpha=0.7) +
  
  # Separate based on the targets
  facet_grid(target_word ~ ., switch='both') +
  
  # Design choices
  theme_bw() +
  theme(strip.text.y.left=element_text(angle=0),
        strip.placement='outside',
        legend.position='none') +
  
  # Remove extraneous labels
  ylab('') +
  xlab('')

ggsave(filename=paste0(output_folder, 'plot-nonadherence.png'), width=7, height=10)

## Non-compliance
this_plot_df <- plottable_df %>% filter(grepl('compli', target_word))

# Create "any" signficance variable among the tests
this_plot_color <- significance_df %>%
  mutate(significance=as.factor(significance)) %>%
  group_by(target_word) %>%
  summarize(anySig=any(significance==1)) %>%
  right_join(this_plot_df)

# Plot the Bonferroni-correct CI's
this_plot_df %>%
  
  # Set the canvas
  ggplot(aes(y=base_word, x=avg, group=base_word)) +
  
  # Set background for signficant comparisons
  geom_rect(data=subset(this_plot_color, anySig==1),
            aes(fill=anySig), xmin=-Inf, xmax=Inf, ymin=-Inf, ymax=Inf) +
  scale_fill_manual(values=c('#FFF8DC')) + 
  
  # Draw the CI's
  geom_segment(data=this_plot_df, aes(y=base_word, yend=base_word, x=lb, xend=ub, col=base_word), lwd=2) +
  scale_color_manual(values=c('#55AE3A', '#00868B', '#FFC125')) + 
  
  # Add the centers
  geom_point(pch=15, col='black', alpha=0.7) +
  
  # Separate based on the targets
  facet_grid(target_word ~ ., switch='both') +
  
  # Design choices
  theme_bw() +
  theme(strip.text.y.left=element_text(angle=0),
        strip.placement='outside',
        legend.position='none') +
  
  # Remove extraneous labels
  ylab('') +
  xlab('')

ggsave(filename=paste0(output_folder, 'plot-noncompliance.png'), width=7, height=10)