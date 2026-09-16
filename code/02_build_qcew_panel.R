# State Corporate Taxes & Local Labor Markets
# 02 - Build County Labor Market Panel

library(tidyverse)

years <- 1990:2010


# Download QCEW annual files

for (year in years) {
  
  url <- paste0(
    "https://data.bls.gov/cew/data/files/",
    year,
    "/csv/",
    year,
    "_annual_singlefile.zip"
  )
  
  zip_file <- paste0("data/raw/qcew_", year, ".zip")
  
  if (!file.exists(zip_file)) {
    download.file(
      url,
      zip_file,
      mode = "wb"
    )
  }
}


# Build county-year labor market panel

county_panel <- data.frame()

for (year in years) {
  
  zip_file <- paste0("data/raw/qcew_", year, ".zip")
  folder <- paste0("data/raw/qcew_", year)
  csv_file <- paste0(
    folder,
    "/",
    year,
    ".annual.singlefile.csv"
  )
  
  # Unzip only if the CSV is not already available
  
  if (!file.exists(csv_file)) {
    unzip(zip_file, exdir = folder)
  }
  
  data <- read_csv(
    csv_file,
    show_col_types = FALSE
  )
  
  county_data <- data %>%
    filter(agglvl_code == 70) %>%
    select(
      area_fips,
      year,
      annual_avg_emplvl,
      avg_annual_pay
    )
  
  county_panel <- bind_rows(
    county_panel,
    county_data
  )
}


# Save county labor market panel

write_csv(
  county_panel,
  "data/processed/county_labor_market_panel.csv"
)


# Load 1990 QCEW data for baseline manufacturing exposure

qcew_1990 <- read_csv(
  "data/raw/qcew_1990/1990.annual.singlefile.csv",
  show_col_types = FALSE
)


# Get total private employment in each county

private_total_1990 <- qcew_1990 %>%
  filter(
    agglvl_code == 71,
    own_code == 5,
    industry_code == "10"
  ) %>%
  select(
    area_fips,
    total_private_employment = annual_avg_emplvl
  )


# Get manufacturing employment in each county

manufacturing_1990 <- qcew_1990 %>%
  filter(
    agglvl_code == 74,
    own_code == 5,
    industry_code == "31-33"
  ) %>%
  select(
    area_fips,
    manufacturing_employment = annual_avg_emplvl
  )


# Calculate 1990 manufacturing employment share

county_exposure <- manufacturing_1990 %>%
  left_join(
    private_total_1990,
    by = "area_fips"
  ) %>%
  filter(
    total_private_employment > 0
  ) %>%
  mutate(
    manufacturing_exposure =
      manufacturing_employment / total_private_employment
  ) %>%
  select(
    area_fips,
    manufacturing_exposure
  )


# Save county manufacturing exposure

write_csv(
  county_exposure,
  "data/processed/county_manufacturing_exposure.csv"
)

