# Precision-Weighted Average (PWA) Test -------------------
#      data: Long data, must be filtered for "subclass"

pwa_test <- function(data) {
  output <- data %>%
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
                 .funs=make_ci)
  
  return(output)
}

# Difference in PWA Test ----------------------------------
#      data: Long data, must be filtered for "subclass"
pwa_diff_test <- function(data) {
  output <- data %>%
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
    mutate(ch=caucasian-hispanic) %>%
    
    summarize(ci_ac=make_ci(ac, ci_width=2.13, test_value=0),
              ci_ah=make_ci(ah, ci_width=2.13, test_value=0),
              ci_ch=make_ci(ch, ci_width=2.13, test_value=0))
  
  return(output)
}



# Plot PWA ------------------------------------------------

pwa_plot <- function(data) {
  plottable_data_v0 <- data %>%
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
                 .funs=~make_ci(., print_format=FALSE)) %>%
    mutate(attr=rep(c('lb', 'ub', 'significance')))
  
  # Reformat the data
  plottable_data_v1 <- plottable_data_v0 %>%
    reshape2::melt(id.vars=c('attr')) %>%
    rename(base_word=variable) %>%
    rename(pwa_average=value) %>%
    reshape2::dcast(base_word ~ attr, value.var='pwa_average') %>%
    mutate(avg = (lb + ub)/2) %>%
    mutate(se=(ub-avg)/1.96) %>%
    mutate(lb_se = avg - se) %>%
    mutate(ub_se = avg + se) %>%
    mutate(base_word=factor(base_word, levels=c('african_american', 'caucasian', 'hispanic')))
  
  # Plot the data
  plottable_data_v1 %>%
    ggplot(aes( color = base_word)) +
    geom_hline(yintercept=1, lwd=2, alpha=0.5) +
    geom_linerange(aes(x = base_word, ymin = lb, ymax = ub),
                   size=2, alpha=0.7, position = position_dodge(width=0.6)) +
    geom_point(aes(x=base_word, y=avg),
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
