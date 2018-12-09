library(survey)
library(Census2016.DataPack)
library(tidyverse)

#====================Classify datasets by the value variable==================

# Persons
summary(CED__Age.min_Sex)
summary(CED__Age5yr_Indigenous_Sex)
summary(CED__Age_NeedsAssistance_Sex)
summary(CED__Age_Sex)
summary(CED__Age_UsualResidence)
summary(CED__AustCitizen_Sex)
summary(CED__BornAust_Sex)
summary(CED__CountryOfBirth_Sex)
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

# Probably won't use this one if we get pushed for memory:
pop1 <- CED__Age_UsualResidence %>%
  as_tibble() %>%
  rename(Freq = persons) %>%
  mutate(Age = as.character(Age)) %>%
  rename(Age014 = Age) %>%
  mutate(Freq = ifelse(Freq == 0, 3, Freq),
         adj = full_pop / sum(Freq),
         Freq = Freq * adj)

pop2 <- CED__Age_NeedsAssistance_Sex %>%
  as_tibble() %>%
  mutate(NeedsAssistance = replace_na(NeedsAssistance)) %>%
  rename(Freq = persons) %>%
  mutate(Age = as.character(Age)) %>%
  rename(Age04514 = Age) %>%
  mutate(Freq = ifelse(Freq == 0, 3, Freq),
         adj = full_pop / sum(Freq),
         Freq = Freq * adj)

pop3 <- CED__Age5yr_Indigenous_Sex %>%
  as_tibble() %>%
  mutate(Indigenous = replace_na(Indigenous),
         Age5yr = as.character(Age5yr)) %>%
  rename(Freq = persons) %>%
  mutate(Freq = ifelse(Freq == 0 , 3, Freq),
         adj = full_pop / sum(Freq),
         Freq = Freq * adj)


pop4 <- CED__OnlyEnglishSpokenHome_Sex %>%
  as_tibble() %>%
  mutate(OnlyEnglishSpokenHome = replace_na(OnlyEnglishSpokenHome)) %>%
  rename(Freq = persons) %>%
  mutate(Freq = ifelse(Freq == 0 , 3, Freq),
         adj = full_pop / sum(Freq),
         Freq = Freq * adj)

pop5 <- CED__Religion_Denomination_Sex %>%
  as_tibble() %>%
  mutate(Denomination = replace_na(Denomination)) %>%
  rename(Freq = persons) %>%
  mutate(Freq = ifelse(Freq == 0 , 3, Freq),
         adj = full_pop / sum(Freq),
         Freq = Freq * adj)

pop1$adj <- NULL
pop2$adj <- NULL
pop3$adj <- NULL
pop4$adj <- NULL
pop5$adj <- NULL
  

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

f_ced_persons <- select(pop2, -Freq) %>%
  full_join(select(pop3, -Freq)) %>%
  inner_join(distinct(possible_ages, Age5yr, Age04514)) %>%
  full_join(select(pop4, -Freq)) %>%
  full_join(select(pop5, -Freq)) %>%
  mutate(persons = 1) 


#------------------weight the seed values to the population-------------------------

facts_svy <- svydesign(~1, data = f_ced_persons, weights = ~persons)

facts_svy <- rake(facts_svy, 
                  sample.margins = list(~Age04514 + Sex + NeedsAssistance + CED_NAME16,
                                        ~Age5yr + Sex + Indigenous + CED_NAME16,
                                        ~Sex + OnlyEnglishSpokenHome + CED_NAME16), 
                  population = list(pop2,
                                    pop3,
                                    pop4))

facts$persons <- weights(facts_svy)

arrange(facts, persons)

full_pop
sum(facts$persons)
sum(round(facts$persons))


