# State Corporate Taxes & Local Labor Markets
# 03 - Build Analysis Panel

library(tidyverse)


# Load processed data

tax <- read_csv(
  "data/processed/state_corporate_tax_rates.csv",
  show_col_types = FALSE
)

labor <- read_csv(
  "data/processed/county_labor_market_panel.csv",
  show_col_types = FALSE
)

exposure <- read_csv(
  "data/processed/county_manufacturing_exposure.csv",
  show_col_types = FALSE
)


# Create state FIPS from county FIPS

labor <- labor %>%
  mutate(
    state_fips = as.numeric(substr(area_fips, 1, 2))
  )


# Merge tax rates, labor market outcomes, and exposure

panel <- labor %>%
  left_join(tax, by = c("state_fips", "year")) %>%
  left_join(exposure, by = "area_fips")


# Keep observations with tax and exposure data

panel <- panel %>%
  filter(
    !is.na(corporate_tax_rate),
    !is.na(manufacturing_exposure),
    annual_avg_emplvl > 0,
    avg_annual_pay > 0
  )


# Create analysis variables

panel <- panel %>%
  mutate(
    tax_x_exposure = corporate_tax_rate * manufacturing_exposure,
    log_employment = log(annual_avg_emplvl),
    log_pay = log(avg_annual_pay)
  )


# Save final analysis panel

write_csv(
  panel,
  "data/processed/final_analysis_panel.csv"
)
