library(Census2016.DataPack)
library(tidyverse)
library(odbc)
library(DBI)
library(dbplyr)
library(Census2016)

# What would really improve this would be some national-level cross tabs of variables we can't match
# at area level. For example, Aust citizen by born in Australia by indigenous status would dramatically 
# improve things; in fact it's a bit ridiculous without it.

#====================Classify datasets by the value variable==================

# Persons
summary(CED__Age.min_Sex)
summary(CED__Age5yr_Indigenous_Sex)
summary(CED__Age_NeedsAssistance_Sex)
summary(CED__Age_Sex)
summary(CED__Age_UsualResidence)
head(CED__AustCitizen_Sex)
head(CED__BornAust_Sex)
head(CED__CountryOfBirth_Sex)
summary(CED__HomeCensusNight_Sex)
summary(CED__OnlyEnglishSpokenHome_Sex)
summary(CED__Religion_Denomination_Sex)

sum(CED__OnlyEnglishSpokenHome_Sex$persons)
sum(CED__Religion_Denomination_Sex$persons)

# Adults
summary(CED__Age_MaxSchoolingCompleted_Sex)
summary(CED__Age_HoursHousekeeping_Sex)
summary(CED__Age_IncomeTotPersonal.max_Sex)
summary(CED__Age_MaritalStatus_Registered)
summary(CED__Age_ProvidedUnpaidChildcare_ForOwnChild_ForOtherChild_Sex)
summary(CED__Age_ProvidedUnpaidDisabilityAssistance_Sex)
summary(CED__Age_Sex_Volunteer)

# says persons but is clearly > 15 or something:
summary(CED__MaxSchoolingCompleted_Sex)


# Responses
summary(CED__Age_MaritalStatus_Sex)
summary(CED__Ancestry)

# Students


# Persons born overseas
summary(CED__CountryOfBirth_YearOfArrival.max)


# Females


# 


#===================Combine datasets==============
replace_na <- function(x){
  x[is.na(x)] <- "Unknown or not available"
  return(x)
}


#-----------------define populations----------------
full_pop <- sum(CED__Age_Sex$persons)

# Probably won't use this as running out of memory:
pop1 <- CED__Age_UsualResidence %>%
  as_tibble() %>%
  rename(Freq = persons) %>%
  mutate(Age = as.character(Age)) %>%
  rename(Age014 = Age) %>%
  mutate(Freq = ifelse(Freq == 0, 2, Freq),
         adj = full_pop / sum(Freq),
         Freq = Freq * adj)

pop2 <- CED__Age_NeedsAssistance_Sex %>%
  as_tibble() %>%
  mutate(NeedsAssistance = replace_na(NeedsAssistance)) %>%
  rename(Freq = persons) %>%
  mutate(Age = as.character(Age)) %>%
  rename(Age04514 = Age) %>%
  mutate(Freq = ifelse(Freq == 0, 2, Freq),
         adj = full_pop / sum(Freq),
         Freq = Freq * adj)

pop3 <- CED__Age5yr_Indigenous_Sex %>%
  as_tibble() %>%
  mutate(Indigenous = replace_na(Indigenous),
         Age5yr = as.character(Age5yr)) %>%
  rename(Freq = persons) %>%
  mutate(Freq = ifelse(Freq == 0 , 2, Freq),
         adj = full_pop / sum(Freq),
         Freq = Freq * adj)


pop4 <- CED__OnlyEnglishSpokenHome_Sex %>%
  as_tibble() %>%
  mutate(OnlyEnglishSpokenHome = replace_na(OnlyEnglishSpokenHome)) %>%
  rename(Freq = persons) %>%
  mutate(Freq = ifelse(Freq == 0 , 2, Freq),
         adj = full_pop / sum(Freq),
         Freq = Freq * adj)

pop5 <- CED__Religion_Denomination_Sex %>%
  as_tibble() %>%
  mutate(Denomination = replace_na(Denomination)) %>%
  rename(Freq = persons) %>%
  mutate(Freq = ifelse(Freq == 0 , 2, Freq),
         adj = full_pop / sum(Freq),
         Freq = Freq * adj)

pop6 <- CED__BornAust_Sex %>%
  as_tibble() %>%
  mutate(BornAust = replace_na(BornAust)) %>%
  rename(Freq = persons) %>%
  mutate(Freq = ifelse(Freq == 0 , 2, Freq),
         adj = full_pop / sum(Freq),
         Freq = Freq * adj)

pop7 <- CED__AustCitizen_Sex %>%
  as_tibble() %>%
  mutate(AustCitizen = replace_na(AustCitizen)) %>%
  rename(Freq = persons) %>%
  mutate(Freq = ifelse(Freq == 0 , 2, Freq),
         adj = full_pop / sum(Freq),
         Freq = Freq * adj)

pop8 <- data_frame(AustCitizen = as.character(c(TRUE, TRUE, TRUE, FALSE, FALSE, FALSE)),
                   Indigenous = rep(c("TRUE", "FALSE", "Unknown or not available"), 2),
                   Freq = c(564443+30485+25554, 18490441, 167905,
                            1411+366+141, 2489716, 15823)) %>%
  # because nowehre to put the "Not stated" - who must have been imputed in CED__AustCitizen_sex
  mutate(Freq = ifelse(Freq == 0 , 3, Freq),
         adj = full_pop / sum(Freq),
         Freq = Freq * adj)


pop1[ , "adj"] <- NULL
pop2[ , "adj"] <- NULL
pop3[ , "adj"] <- NULL
pop4[ , "adj"] <- NULL
pop5[ , "adj"] <- NULL
pop6[ , "adj"] <- NULL  
pop7[ , "adj"] <- NULL
pop8[ , "adj"] <- NULL

#----------------------------define our seed values--------------
possible_ages <- data_frame(Age = 0:100) %>%
  mutate(Age04514 = as.character(cut(Age, c(-1, 4, 14, 19, 24, 34, 44, 54, 64, 74, 84, 200), 
                                     labels = as.character(unique(CED__Age_NeedsAssistance_Sex$Age)))),
         Age014 = as.character(cut(Age, c(-1, 14, 24, 34, 44, 54, 64, 74, 84, 200),
                                   labels = as.character(unique(CED__Age_UsualResidence$Age)))),
         Age5yr = as.character(cut(Age, c(-1, 4, 9, 14, 19, 24, 29, 34, 39, 44, 49, 54, 59, 64, 200),
                                   labels = as.character(unique(CED__Age5yr_Indigenous_Sex$Age))))) %>%
  select(-Age) %>%
  distinct()

ced_persons_seed <- select(pop2, -Freq) %>%
  full_join(select(pop3, -Freq)) %>%
  inner_join(distinct(possible_ages, Age5yr, Age04514)) %>%
  inner_join(distinct(possible_ages, Age5yr, Age04514)) 

  # full_join(select(pop4, -Freq)) %>%
  # full_join(select(pop5, -Freq)) %>%
  # full_join(select(pop6, -Freq)) %>%
  # full_join(select(pop7, -Freq)) %>%
  # full_join(select(pop8, -Freq)) %>%
  # mutate(persons = 1) 

con <- dbConnect(odbc(), "sqlserver", database = "ozdata")
dbGetQuery(con, "DROP TABLE IF EXISTS ced_persons_seed_incomplete")
dbWriteTable(con, name = "ced_persons_seed_incomplete", value = ced_persons_seed)

for(p in c("pop2", "pop3", "pop4", "pop5", "pop6", "pop7", "pop8")){
  dbGetQuery(con, paste0("DROP TABLE IF EXISTS ", p))
  dbWriteTable(con, name = p, value = get(p))
}

dbGetQuery(con, "DROP TABLE IF EXISTS ced_persons_seed;")

sql <- paste(readLines("sql/finish-getting-table-ready.sql"), collapse = "\n")

dbDisconnect(con)

# Then run in SQL Server the ./SQL/rake-ced.sql script. Note it takes a while to run
