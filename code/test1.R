library(readxl)
library(ggplot2)
library(tidyr) # maybe need to install these packages
library(dplyr)
# An important disclosure is that due to the way the data is tracked, >1980 will have less overall.
data <- read_excel("M810091.xlsx")

data_long <- data %>%
  pivot_longer(cols = -DataSeries, 
               names_to = "Year", 
               values_to = "Value") %>%
  mutate(Year = as.numeric(Year))

str(data)

summary(data)

cor(data)


# TFR
ggplot(data_long %>% filter(DataSeries=="TotalFertilityRate(TFR)(PerFemale)"),
       aes(x = Year, y = Value)) +
  geom_line(color = "red", size = 1) +
  geom_point(color="black", size = 1) + 
  labs(title="Total Fertility Rate (Per Female)",
       x= "Year",
       y = "Total Fertility Rate") +
  theme_minimal()
      

# 15-19 Years
ggplot(data_long %>% filter(DataSeries == "15-19Years(PerThousandFemales)"), 
       aes(x = Year, y = Value)) +
  geom_line(color = "red", size = 1) +
  geom_point(color = "black", size = 1) +
  labs(title = "15-19 Years (Per Thousand Females)",
       x = "Year", 
       y = "Births per 1,000 Females") +
  theme_minimal()


#TFR vs 15-19 years 
ggplot(data_long %>% 
         filter(DataSeries == "15-19Years(PerThousandFemales)"),
       aes(x = Value)) +
  geom_histogram(binwidth = 1,
                 fill = "red",
                 color = "black") +
  labs(title = "Distribution of 15–19 Fertility Rates",
       x = "Births per 1,000 Females",
       y = "Frequency") +
  theme_minimal()
