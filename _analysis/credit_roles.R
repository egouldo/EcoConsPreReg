# Generate CRediT roles from a Google Sheet with `tenzing::`

library(tidyverse)
library(tenzing)

credit_gsheet <- googlesheets4::read_sheet("https://docs.google.com/spreadsheets/d/1NDoS2GZmsPLazMFotlRx51jOr9r2nACeWfM4SqFeuM8/edit?pli=1&gid=0#gid=0")

credit_roles_key <- googlesheets4::read_sheet("https://docs.google.com/spreadsheets/d/1NDoS2GZmsPLazMFotlRx51jOr9r2nACeWfM4SqFeuM8/edit?pli=1&gid=0#gid=0", sheet = 2)

config_path <- system.file("config/title_validation.yaml", package = "tenzing")

contrib_table <- 
  credit_gsheet %>%
  filter( if_any(contains("Consent"), ~ . == "Y")) %>%
  select(-contains("Consent")) %>%
  rename(!!! {credit_roles_key %>%
      select(2, 1) %>%
      deframe() }
  ) %>%
  tenzing::clean_contributors_table()

# Validate the contributors table

validate_output_instance <- ValidateOutput$new(config_path = config_path)

validate_results <- validate_output_instance$run_validations(contributors_table = contrib_table)

stopifnot(
  purrr::map(validate_results, "type") %>% 
    purrr::map_lgl(~ .x == "success" | .x == "warning") %>% 
    all()
)

# purrr::map(validate_results, "type")
# purrr::map(validate_results, "message")

# Write the contributors table to a .rmd file

tenzing::print_yaml(contributors_table = contrib_table) %>% 
  write_lines("inst/CONTRIBUTORS.rmd")
