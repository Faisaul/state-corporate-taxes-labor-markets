# State Corporate Taxes & Local Labor Markets
# 04 - Main Analysis

library(tidyverse)
library(fixest)


# Load final analysis panel

panel <- read_csv(
  "data/processed/final_analysis_panel.csv",
  show_col_types = FALSE
)


# Main models: county and year fixed effects

model_employment <- feols(
  log_employment ~ tax_x_exposure | area_fips + year,
  cluster = ~ state_fips,
  data = panel
)

model_pay <- feols(
  log_pay ~ tax_x_exposure | area_fips + year,
  cluster = ~ state_fips,
  data = panel
)


# Preferred models: county and state-year fixed effects

model_employment_stateyear <- feols(
  log_employment ~ tax_x_exposure | area_fips + state_fips^year,
  cluster = ~ state_fips,
  data = panel
)

model_pay_stateyear <- feols(
  log_pay ~ tax_x_exposure | area_fips + state_fips^year,
  cluster = ~ state_fips,
  data = panel
)


# Robustness: exclude highly manufacturing-intensive counties

panel_exposure_robust <- panel %>%
  filter(manufacturing_exposure < 0.75)

model_pay_exposure_robust <- feols(
  log_pay ~ tax_x_exposure | area_fips + state_fips^year,
  cluster = ~ state_fips,
  data = panel_exposure_robust
)


# Display regression results

summary(model_employment)
summary(model_pay)
summary(model_employment_stateyear)
summary(model_pay_stateyear)
summary(model_pay_exposure_robust)


# Display main regression table

etable(
  model_employment,
  model_pay,
  model_employment_stateyear,
  model_pay_stateyear,
  model_pay_exposure_robust,
  headers = c(
    "Employment",
    "Pay",
    "Employment",
    "Pay",
    "Pay Robustness"
  )
)


# Build regression results table

results_table <- data.frame(
  model = c(
    "Employment - County + Year FE",
    "Pay - County + Year FE",
    "Employment - County + State-Year FE",
    "Pay - County + State-Year FE",
    "Pay - Exclude High Exposure"
  ),
  coefficient = c(
    coef(model_employment)["tax_x_exposure"],
    coef(model_pay)["tax_x_exposure"],
    coef(model_employment_stateyear)["tax_x_exposure"],
    coef(model_pay_stateyear)["tax_x_exposure"],
    coef(model_pay_exposure_robust)["tax_x_exposure"]
  ),
  standard_error = c(
    se(model_employment)["tax_x_exposure"],
    se(model_pay)["tax_x_exposure"],
    se(model_employment_stateyear)["tax_x_exposure"],
    se(model_pay_stateyear)["tax_x_exposure"],
    se(model_pay_exposure_robust)["tax_x_exposure"]
  )
)


# Save regression results

write_csv(
  results_table,
  "output/tables/regression_results.csv"
)


# Employment results figure

employment_plot <- results_table %>%
  filter(grepl("Employment", model)) %>%
  mutate(
    lower = coefficient - 1.96 * standard_error,
    upper = coefficient + 1.96 * standard_error
  )

employment_figure <- ggplot(
  employment_plot,
  aes(
    x = coefficient,
    y = model
  )
) +
  geom_point(size = 3) +
  geom_errorbarh(
    aes(
      xmin = lower,
      xmax = upper
    ),
    height = 0.15
  ) +
  geom_vline(
    xintercept = 0,
    linetype = "dashed"
  ) +
  labs(
    title = "Corporate Tax Exposure and County Employment",
    subtitle = "Coefficient estimates with 95% confidence intervals",
    x = "Coefficient Estimate",
    y = NULL
  ) +
  theme_minimal()

employment_figure

ggsave(
  "output/figures/employment_results.png",
  plot = employment_figure,
  width = 8,
  height = 4,
  dpi = 300
)


# Pay results figure

pay_plot <- results_table %>%
  filter(grepl("Pay", model)) %>%
  mutate(
    lower = coefficient - 1.96 * standard_error,
    upper = coefficient + 1.96 * standard_error
  )

pay_figure <- ggplot(
  pay_plot,
  aes(
    x = coefficient,
    y = model
  )
) +
  geom_point(size = 3) +
  geom_errorbarh(
    aes(
      xmin = lower,
      xmax = upper
    ),
    height = 0.15
  ) +
  geom_vline(
    xintercept = 0,
    linetype = "dashed"
  ) +
  labs(
    title = "Corporate Tax Exposure and County Pay",
    subtitle = "Coefficient estimates with 95% confidence intervals",
    x = "Coefficient Estimate",
    y = NULL
  ) +
  theme_minimal()

pay_figure

ggsave(
  "output/figures/pay_results.png",
  plot = pay_figure,
  width = 8,
  height = 4,
  dpi = 300
)

# Descriptive statistics

descriptive_stats <- panel %>%
  summarise(
    observations = n(),
    counties = n_distinct(area_fips),
    mean_employment = mean(annual_avg_emplvl),
    median_employment = median(annual_avg_emplvl),
    mean_pay = mean(avg_annual_pay),
    median_pay = median(avg_annual_pay),
    mean_tax_rate = mean(corporate_tax_rate),
    mean_manufacturing_exposure = mean(manufacturing_exposure)
  )

write_csv(
  descriptive_stats,
  "output/tables/descriptive_statistics.csv"
)

descriptive_stats