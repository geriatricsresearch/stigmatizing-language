make_ci <- function(k, decimals=2, test_value=1, ci_width=1.96, print_format=TRUE) {
  avg <- mean(k, na.rm=TRUE)
  std <- sd(k, na.rm=TRUE)
  lb <- round(avg - ci_width*std, 3)
  ub <- round(avg + ci_width*std, 3)
  
  
  if (!is.na(lb) & !is.na(ub)) {
    stat_signif <- ifelse(lb<test_value & ub>test_value, FALSE, TRUE)
    
    if (print_format) {
      
      ifelse(stat_signif,
             paste0('(', lb, ', ', ub, ')*'),
             paste0('(', lb, ', ', ub, ')'))
    } else {
      c(lb, ub, stat_signif)
    }
    
  } else {
    NA
  }
}


bonferroniCI <- function(boot_data, num_tests, vars=c('african_american', 'caucasian', 'hispanic'), target_word_group=TRUE, print_format=TRUE) {
  ci_width <- qnorm(1-(0.05/num_tests))
  
  if (target_word_group==TRUE) {
    boot_data %>%
      group_by(target_word, bootstrap) %>%
      summarize_at(.vars=vars,
                   .funs=~mean(., na.rm=TRUE)) %>%
      summarize_at(.vars=vars,
                   .funs=~make_ci(., ci_width=ci_width, print_format=print_format))
  } else {
    boot_data %>%
      group_by(bootstrap) %>%
      summarize_at(.vars=vars,
                   .funs=~mean(., na.rm=TRUE)) %>%
      summarize_at(.vars=vars,
                   .funs=~make_ci(., ci_width=ci_width))
  }
  
}


euclidCI <- function(boot_data) {
  boot_data %>%
    
    # For each bootstrap dataset, get the mean cosine distance between each base/target pair
    group_by(bootstrap, target_word) %>%
    
    summarize(mean_a=mean(african_american),
              mean_c=mean(caucasian),
              mean_h=mean(hispanic)) %>%
    
    ungroup() %>%
    
    # For each bootstrap dataset, calculate the Euclidean distance of means
    group_by(bootstrap) %>%
    mutate(a_c=mean_a-mean_c) %>%
    mutate(a_h=mean_a-mean_h) %>%
    mutate(c_h=mean_c-mean_h) %>%
    
    mutate(a_c2=a_c^2) %>%
    mutate(a_h2=a_h^2) %>%
    mutate(c_h2=c_h^2) %>%
    
    summarize(euclid_ac=sqrt(sum(a_c2)),
              euclid_ah=sqrt(sum(a_h2)),
              euclid_ch=sqrt(sum(c_h2))) %>%
    
    ungroup() %>%
    
    # Get the mean and sd for the Euclidean distances
    summarize_at(.vars=c('euclid_ac', 'euclid_ah', 'euclid_ch'),
                 .funs=c('mean', 'sd')) %>%
    
    # Reformat the table
    gather(var, val) %>%
    separate(var, c('variable', 'comparison', 'stat')) %>%
    spread(stat, val) %>%
    select(-variable) %>%
    
    # Calculate the confidence interval bounds
    mutate(lb=mean-2.13*sd) %>%
    mutate(ub=mean+2.13*sd)
}
