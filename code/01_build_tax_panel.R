# State Corporate Taxes & Local Labor Markets
# 01 - Build State Corporate Tax Panel

library(tidyverse)

tax_raw <- read_csv("data/raw/Corp-Tax-Rates.csv")

dim(tax_raw)
names(tax_raw)
head(tax_raw)

tax <- tax_raw %>%
  rename(
    state = State,
    year = Year,
    state_fips = FIPS,
    corporate_tax_rate = `State Corporate Tax Rate`,
    federal_tax_rate = `Federal Corporate Tax Rate`
  )

tax %>%
  summarise(
    first_year = min(year),
    last_year = max(year),
    states = n_distinct(state),
    missing_tax_rates = sum(is.na(corporate_tax_rate))
  )
tax_changes <- tax %>%
  arrange(state, year) %>%
  group_by(state) %>%
  mutate(
    tax_change = corporate_tax_rate - lag(corporate_tax_rate)
  ) %>%
  ungroup()

tax_changes %>%
  filter(!is.na(tax_change), tax_change != 0) %>%
  summarise(
    number_of_changes = n(),
    states_with_changes = n_distinct(state),
    average_change = mean(tax_change),
    largest_cut = min(tax_change),
    largest_increase = max(tax_change)
  )
# Correct apparent decimal-place error in West Virginia, 1989
tax <- tax %>%
  mutate(
    corporate_tax_rate = if_else(
      state == "West Virginia" & year == 1989,
      0.0952,
      corporate_tax_rate
    )
  )
# Correct apparent decimal-place error in Hawaii, 1989

tax <- tax %>%
  mutate(
    corporate_tax_rate = if_else(
      state == "Hawaii" & year == 1989,
      0.064,
      corporate_tax_rate
    )
  )

write_csv(
  tax,
  "data/processed/state_corporate_tax_rates.csv"
)