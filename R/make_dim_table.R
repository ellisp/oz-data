#' @importFrom dplyr %>% pull mutate select
#' @importFrom forcats fct_relevel
make_dim_table <- function(data, 
                           col_name, 
                           tab_name = paste0("d_", col_name), 
                           first_levels = NULL,
                           na_replacement = "Unknown or not applicable",
                           eff_from = as.Date("1900-01-01"),
                           eff_to   = as.Date("2999-12-30")){
  
  
  
  if(!class(pull(data, col_name)) %in% c("factor", "character")){
    stop("Column col_name of data should be character or factor")
  }
  
  number_nas <- sum(is.na(data[ , col_name]))
  if(number_nas > 0){
    warning(paste0("Replacing ", number_nas, " with '", na_replacement, "'."))
    data[ , col_name] <- ifelse(is.na(data[ , col_name]), 
                                na_replacement, 
                                pull(data , col_name))
  }    
  
  
  suppressWarnings({
    levs <- unique(pull(data, col_name)) %>%
      forcats::fct_relevel(first_levels) %>%
      forcats::fct_relevel(na_replacement, after = Inf) %>%
      levels()
  })
    
  the_table <- data_frame(
    c1 = levs
  ) %>%
    mutate(c2 = 1:n()) %>%
    select(c2, c1) %>%
    mutate(effective_from = eff_from,
           effective_to   = eff_to)

  names(the_table)[1:2] <- c(paste0(col_name, "_id"), col_name)
  
  assign(tab_name, the_table, envir = globalenv())
  
  data <- left_join(data, the_table[, 1:2], by = col_name)
  data[ , col_name] <- NULL
  return(data)
}

