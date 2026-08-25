# calibration/scripts/02_build_calibration_inputs.R
# =============================================================================
# Build model-ready calibration inputs for the recursive-dynamic GTAP-LU model.
#
# FINAL REPLICATION-PACKAGE ROLE
# ------------------------------
# This is the scientific/data-processing script of the calibration workflow.
# The companion 01_fetch_calibration_inputs.R is responsible only for obtaining
# and preserving authoritative raw inputs.
#
# Current implementation:
#   [IMPLEMENTED] Task 1: SSP1 / SSP3 population and GDP paths
#   [RESERVED]    GAEZ-v5 crop-yield -> lndtfp processing
#   [RESERVED]    Trade-barrier workbook -> policy-shock processing
#
# Run from RStudio with the project root as the working directory:
#
#   getwd()
#   # "C:/Users/JesusMERCADO/GAMSProjects/GTAP_AEZ/rdyn"
#
#   source("calibration/scripts/02_build_calibration_inputs.R")
#
# PRINCIPLES
# ----------
# 1. Raw files are never modified.
# 2. The canonical MercosurMap.gms mapping controls the 10 GTAP target regions.
# 3. SSP growth is built at the 10-region level from balanced country subsets;
#    regional per-capita GDP is then calculated from regional GDP / population.
# 4. GTAP 2017 levels are not overwritten by SSP absolute levels.  The GAMS
#    include files apply SSP growth paths to the normalized GTAP base.
# 5. Source data are on five-year nodes. Regional growth paths are constructed
#    from balanced country subsets and annualized by log-linear interpolation.
# 6. Because the model benchmark is 2017 and this is a forward SSP baseline,
#    2017-2025 population and GDP are smoothed directly between the 2017
#    Historical Reference anchor and the 2025 SSP anchor. This avoids embedding
#    the realized 2018-2020 recession/COVID shock in the DynCal productivity path.
# 6. Historical Reference is used through 2020.  SSP-specific projections are
#    used from 2025 onward.  Thus the 2020->2025 bridge is scenario specific.
# 7. The model is annual: 2017-2050, gap(t)=1.
# 8. Generated .inc files are intended to be included AFTER cal.gms in a
#    dedicated experiment launcher, not by editing the canonical model equations.
#
# AUTHORITATIVE SSP SOURCE
# ------------------------
# Workbook:
#   ssp_basic_drivers_release_3.2_full.xlsx
#
# Population:
#   Model    = IIASA-WiC POP 2025
#   Variable = Population
#   Unit     = million
#
# GDP:
#   Model    = OECD ENV-Growth 2025
#   Variable = GDP|PPP
#   Unit     = billion USD_2017/yr
#
# Headline scenarios:
#   SSP1
#   SSP3
#
# The GDP source provides Afghanistan, Palestine, Syria and Venezuela SSP
# projections on the workbook's dedicated turbulent-economy sheet.  Their
# historical GDP records remain in the main sheet and are used for the
# 2017-2020 historical bridge.
#
# Three population economies (Guadeloupe, Martinique and Réunion) have no GDP
# projection in the OECD series.  They remain in population totals, while GDP
# aggregation follows the IIASA/OECD source coverage and omits their GDP.
# This omission is written explicitly to the audit outputs.
#
# OUTPUTS
# -------
# calibration/processed/ssp/
#   ssp_country_to_model_region_crosswalk.csv
#   ssp_country_growth_basis_coverage.csv
#   ssp_model_region_annual_2017_2050.csv
#
# calibration/output/inc/
#   ssp1_socioeconomic_2017_2050.inc
#   ssp3_socioeconomic_2017_2050.inc
#
# calibration/audit/ssp/
#   ssp_mapping_fallbacks.csv
#   ssp_direct_gtap_mapping_validation.csv
#   ssp_dropped_noncountry_regions.csv
#   ssp_growth_basis_coverage.csv
#   ssp_growth_basis_exclusions.csv
#   ssp_validation_summary.csv
#   ssp_negative_ggdppc_targets.csv
#
# The script ends with a generic SUMMARY section suitable for a replication log.
# =============================================================================


# =============================================================================
# 0. Configuration
# =============================================================================

options(stringsAsFactors = FALSE, width = 220)

PROJECT_ROOT <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)

CALIBRATION_DIR <- file.path(PROJECT_ROOT, "calibration")
RAW_SSP_DIR     <- file.path(CALIBRATION_DIR, "raw", "ssp")
PROCESSED_SSP   <- file.path(CALIBRATION_DIR, "processed", "ssp")
OUTPUT_INC_DIR  <- file.path(CALIBRATION_DIR, "output", "inc")
AUDIT_SSP_DIR   <- file.path(CALIBRATION_DIR, "audit", "ssp")

dir.create(PROCESSED_SSP,  recursive = TRUE, showWarnings = FALSE)
dir.create(OUTPUT_INC_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(AUDIT_SSP_DIR, recursive = TRUE, showWarnings = FALSE)

SSP_WORKBOOK <- file.path(
  RAW_SSP_DIR,
  "ssp_basic_drivers_release_3.2_full.xlsx"
)

# Canonical MERCOSUR aggregation files.
#
# IMPORTANT:
#   Mercosur2Map.gms is pinned here because this calibration belongs to the
#   MERCOSUR project.  agggtap_ln.gms is retained as provenance/audit only.
#   We deliberately DO NOT resolve the mapping by following whatever
#   $setGlobal Aggregation happens to be active in agggtap_ln.gms, because that
#   launcher has also been used during development for unrelated aggregation
#   experiments.
AGGGTAP_FILE <- file.path(PROJECT_ROOT, "agggtap_ln.gms")
MAPPING_FILE <- file.path(PROJECT_ROOT, "Mercosur2Map.gms")


read_agggtap_aggregation_macro <- function(path) {

  if (!file.exists(path)) {
    return(NA_character_)
  }

  lines <- readLines(
    path,
    warn = FALSE,
    encoding = "UTF-8"
  )

  hit <- grep(
    "^\\s*\\$setGlobal\\s+Aggregation\\s+",
    lines,
    ignore.case = TRUE
  )

  if (!length(hit)) {
    return(NA_character_)
  }

  # Report the last assignment, which is the effective value if the macro was
  # redefined earlier in the file.
  line <- lines[tail(hit, 1)]

  value <- sub(
    "^\\s*\\$setGlobal\\s+Aggregation\\s+",
    "",
    line,
    ignore.case = TRUE
  )

  value <- sub("\\s*\\*.*$", "", value)
  value <- trimws(value)
  value <- gsub("^[\"']|[\"']$", "", value)

  if (!nzchar(value)) NA_character_ else value
}


AGGGTAP_AGGREGATION_MACRO <- read_agggtap_aggregation_macro(
  AGGGTAP_FILE
)

TARGET_SCENARIOS <- c("SSP1", "SSP3")

BASE_YEAR            <- 2017L
HISTORICAL_END_YEAR  <- 2020L
SCENARIO_START_YEAR  <- 2025L
MODEL_END_YEAR       <- 2050L
MODEL_YEARS          <- BASE_YEAR:MODEL_END_YEAR

POP_MODEL    <- "IIASA-WiC POP 2025"
POP_VARIABLE <- "Population"
POP_UNIT     <- "million"

GDP_MODEL    <- "OECD ENV-Growth 2025"
GDP_VARIABLE <- "GDP|PPP"
GDP_UNIT     <- "billion USD_2017/yr"

TURB_GDP_MODEL <- "OECD ENV-Growth 2025 [Turbulent Economy Data]"

EXPECTED_TARGET_REGIONS <- c(
  "Brazil",
  "Argentina",
  "Paraguay",
  "Uruguay",
  "Bolivia",
  "EU27",
  "China",
  "US",
  "RestLatAm",
  "ROW"
)

TOL <- 1e-10


# =============================================================================
# 1. Package and input checks
# =============================================================================

required_packages <- c("readxl", "countrycode")

missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages)) {
  stop(
    "Missing required R package(s): ",
    paste(missing_packages, collapse = ", "),
    "\nInstall once with:\n  install.packages(c(",
    paste(sprintf('"%s"', missing_packages), collapse = ", "),
    "))"
  )
}

if (!file.exists(SSP_WORKBOOK)) {
  stop(
    "Missing SSP workbook:\n  ", SSP_WORKBOOK,
    "\nRun calibration/scripts/01_fetch_calibration_inputs.R ",
    "or place the pinned official workbook there."
  )
}

if (!file.exists(MAPPING_FILE)) {
  stop(
    "Missing pinned MERCOSUR mapping:\n  ",
    MAPPING_FILE,
    "\nThis calibration must use Mercosur2Map.gms."
  )
}

if (!file.exists(AGGGTAP_FILE)) {
  warning(
    "agggtap_ln.gms was not found at:\n  ",
    AGGGTAP_FILE,
    "\nThe SSP build can proceed because Mercosur2Map.gms is pinned explicitly, ",
    "but aggregation-launcher provenance cannot be audited."
  )
}

if (
  !is.na(AGGGTAP_AGGREGATION_MACRO) &&
  !AGGGTAP_AGGREGATION_MACRO %in% c("Mercosur2", "Mercosur", "Mercosur2Map", "MercosurMap")
) {
  warning(
    "agggtap_ln.gms currently has $setGlobal Aggregation = ",
    AGGGTAP_AGGREGATION_MACRO,
    ".\nThe calibration build will use the pinned ",
    "MERCOSUR mapping:\n  ",
    MAPPING_FILE,
    "\nBefore rebuilding the aggregated GTAP database, verify that agggtap_ln.gms ",
    "is switched back to the MERCOSUR aggregation."
  )
}


# =============================================================================
# 2. Utility functions
# =============================================================================

trim_chr <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  trimws(x)
}


write_csv <- function(x, path) {
  utils::write.csv(
    x,
    path,
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}


assert_unique_key <- function(df, key, label) {
  if (!nrow(df)) {
    stop(label, ": zero rows after filtering.")
  }

  dup <- duplicated(df[key]) | duplicated(df[key], fromLast = TRUE)

  if (any(dup)) {
    bad <- unique(df[dup, key, drop = FALSE])
    bad_file <- file.path(
      AUDIT_SSP_DIR,
      paste0("ERROR_duplicate_", gsub("[^A-Za-z0-9]+", "_", label), ".csv")
    )
    write_csv(bad, bad_file)

    stop(
      label, ": duplicated key records found.\nAudit:\n  ", bad_file
    )
  }
}


safe_ratio <- function(num, den, label) {
  if (any(!is.finite(num)) || any(!is.finite(den)) || any(den <= 0)) {
    stop(label, ": invalid numerator/denominator.")
  }
  num / den
}


# Convert a filtered IAMC-style wide data frame to long format.
wide_to_long <- function(df, value_name) {
  year_cols <- grep("^(19|20|21)[0-9]{2}$", names(df), value = TRUE)

  if (!length(year_cols)) {
    stop("No year columns found while converting ", value_name, " to long format.")
  }

  id_cols <- setdiff(names(df), year_cols)

  long <- stats::reshape(
    as.data.frame(df),
    varying = year_cols,
    v.names = value_name,
    timevar = "year",
    times = as.integer(year_cols),
    direction = "long",
    idvar = id_cols
  )

  rownames(long) <- NULL
  long$year <- as.integer(long$year)
  long[[value_name]] <- suppressWarnings(as.numeric(long[[value_name]]))

  long <- long[is.finite(long[[value_name]]), , drop = FALSE]
  long
}


# Build an annual positive level path using log-linear interpolation.
# Historical nodes <= 2020 and SSP nodes >= 2025 are joined explicitly.
annualize_one_series <- function(
    hist_df,
    scen_df,
    value_col,
    scenario,
    region_name,
    years = MODEL_YEARS) {

  h <- hist_df[
    hist_df$Region == region_name &
      hist_df$year <= HISTORICAL_END_YEAR,
    c("year", value_col),
    drop = FALSE
  ]

  s <- scen_df[
    scen_df$Region == region_name &
      scen_df$Scenario == scenario &
      scen_df$year >= SCENARIO_START_YEAR,
    c("year", value_col),
    drop = FALSE
  ]

  nodes <- rbind(h, s)
  names(nodes) <- c("year", "value")

  nodes <- nodes[
    is.finite(nodes$value) &
      nodes$value > 0 &
      is.finite(nodes$year),
    ,
    drop = FALSE
  ]

  nodes <- nodes[order(nodes$year), , drop = FALSE]

  # If a year appears twice, scenario data should take precedence.
  nodes <- nodes[!duplicated(nodes$year, fromLast = TRUE), , drop = FALSE]

  if (!nrow(nodes)) {
    return(NULL)
  }

  if (min(nodes$year) > min(years) || max(nodes$year) < max(years)) {
    return(NULL)
  }

  ylog <- stats::approx(
    x = nodes$year,
    y = log(nodes$value),
    xout = years,
    method = "linear",
    rule = 1,
    ties = "ordered"
  )$y

  if (any(!is.finite(ylog))) {
    return(NULL)
  }

  data.frame(
    Scenario = scenario,
    Region = region_name,
    year = years,
    value = exp(ylog),
    stringsAsFactors = FALSE
  )
}


annualize_all_regions <- function(
    hist_df,
    scen_df,
    value_col,
    scenario,
    regions) {

  pieces <- lapply(
    regions,
    function(reg) {
      annualize_one_series(
        hist_df = hist_df,
        scen_df = scen_df,
        value_col = value_col,
        scenario = scenario,
        region_name = reg,
        years = MODEL_YEARS
      )
    }
  )

  ok <- !vapply(pieces, is.null, logical(1))

  list(
    data = if (any(ok)) do.call(rbind, pieces[ok]) else NULL,
    failed_regions = regions[!ok]
  )
}


# =============================================================================
# 3. Parse the canonical 10-region GAMS mapping
# =============================================================================

mapping_lines <- readLines(
  MAPPING_FILE,
  warn = FALSE,
  encoding = "UTF-8"
)

start_mapr <- grep(
  "^\\s*set\\s+mapr\\s*\\(\\s*reg\\s*,\\s*r\\s*\\)\\s*/",
  mapping_lines,
  ignore.case = TRUE
)

if (length(start_mapr) != 1L) {
  stop(
    "Could not identify exactly one 'set mapr(reg,r) /' block in:\n  ",
    MAPPING_FILE
  )
}

end_candidates <- which(
  seq_along(mapping_lines) > start_mapr &
    grepl("^\\s*/\\s*;\\s*$", mapping_lines)
)

if (!length(end_candidates)) {
  stop("Could not find the end of mapr(reg,r) in: ", MAPPING_FILE)
}

end_mapr <- min(end_candidates)

mapr_block <- mapping_lines[
  (start_mapr + 1L):(end_mapr - 1L)
]

mapr_block <- sub("\\*.*$", "", mapr_block)
mapr_block <- trimws(mapr_block)
mapr_block <- mapr_block[nzchar(mapr_block)]

map_pairs <- lapply(
  mapr_block,
  function(line) {
    m <- regexec(
      "^([A-Za-z0-9_]+)\\s*\\.\\s*([A-Za-z0-9_]+)\\s*$",
      line
    )
    z <- regmatches(line, m)[[1]]

    if (length(z) == 3L) {
      c(source_gtap = toupper(z[2]), target_region = z[3])
    } else {
      NULL
    }
  }
)

map_pairs <- map_pairs[!vapply(map_pairs, is.null, logical(1))]

if (!length(map_pairs)) {
  stop("No mapr source-target pairs could be parsed from: ", MAPPING_FILE)
}

mapr <- as.data.frame(
  do.call(rbind, map_pairs),
  stringsAsFactors = FALSE
)

assert_unique_key(mapr, "source_gtap", "canonical mapr")

actual_targets <- sort(unique(mapr$target_region))
expected_targets <- sort(EXPECTED_TARGET_REGIONS)

if (!identical(actual_targets, expected_targets)) {
  stop(
    "Canonical mapping target regions do not match the locked 10-region design.\n",
    "Expected:\n  ", paste(expected_targets, collapse = " | "),
    "\nFound:\n  ", paste(actual_targets, collapse = " | ")
  )
}

if (nrow(mapr) != 160L) {
  warning(
    "Canonical mapr contains ", nrow(mapr),
    " source regions; the validated GTAP11 mapping previously contained 160."
  )
}

direct_iso_target <- setNames(
  mapr$target_region[!grepl("^X", mapr$source_gtap)],
  mapr$source_gtap[!grepl("^X", mapr$source_gtap)]
)


# =============================================================================
# 4. SSP-country -> ISO3 -> 10-region concordance
# =============================================================================

# Country-name aliases observed in the SSP Basic Drivers workbook or commonly
# handled inconsistently across ISO name dictionaries.
manual_name_to_iso3 <- c(
  "Kosovo" = "XKX",
  "Micronesia" = "FSM",
  "Palestine" = "PSE",
  "Turkey" = "TUR",
  "United States Virgin Islands" = "VIR",
  "Macao" = "MAC",
  "Moldova" = "MDA",
  "North Korea" = "PRK",
  "Réunion" = "REU",
  "Curaçao" = "CUW",
  "Czechia" = "CZE",
  "Eswatini" = "SWZ",
  "Cabo Verde" = "CPV",
  "Timor-Leste" = "TLS"
)

EU27_ISO3 <- c(
  "AUT", "BEL", "BGR", "HRV", "CYP", "CZE", "DNK",
  "EST", "FIN", "FRA", "DEU", "GRC", "HUN", "IRL",
  "ITA", "LVA", "LTU", "LUX", "MLT", "NLD", "POL",
  "PRT", "ROU", "SVK", "SVN", "ESP", "SWE"
)

FOCAL_REGION_BY_ISO3 <- c(
  "BRA" = "Brazil",
  "ARG" = "Argentina",
  "PRY" = "Paraguay",
  "URY" = "Uruguay",
  "BOL" = "Bolivia"
)

is_ssp_aggregate_name <- function(x) {
  grepl("\\(R(5|9|10)\\)$", x) | x == "World"
}


get_un_subregion <- function(iso3) {

  cl <- countrycode::codelist

  required_codelist_cols <- c("iso3c", "un.regionsub.name")

  if (!all(required_codelist_cols %in% names(cl))) {
    stop(
      "Installed countrycode package does not expose the expected columns: ",
      paste(required_codelist_cols, collapse = " | ")
    )
  }

  idx <- match(iso3, cl$iso3c)
  trim_chr(cl$un.regionsub.name[idx])
}


assign_mercosur_target <- function(iso3) {

  iso3 <- toupper(iso3)
  target <- rep(NA_character_, length(iso3))
  method <- rep(NA_character_, length(iso3))

  # -------------------------------------------------------------------
  # A. Direct GTAP11 source regions: mapr(reg,r) is authoritative.
  # -------------------------------------------------------------------
  direct_mapr <- mapr[
    !grepl("^X", mapr$source_gtap),
    c("source_gtap", "target_region"),
    drop = FALSE
  ]

  direct_lookup <- stats::setNames(
    direct_mapr$target_region,
    direct_mapr$source_gtap
  )

  direct_hit <- iso3 %in% names(direct_lookup)

  target[direct_hit] <- unname(
    direct_lookup[iso3[direct_hit]]
  )

  method[direct_hit] <- "direct_GTAP11_source_region"

  # -------------------------------------------------------------------
  # B. SSP countries/territories represented inside GTAP composite X*
  #    source regions.
  #
  # For these only, reconstruct the project regional rule.
  # -------------------------------------------------------------------
  remaining <- is.na(target)

  if (any(remaining)) {

    # Keep explicit focal/EU/China/US rules as safeguards. In the current
    # GTAP11 mapping these economies are direct source regions and therefore
    # should already have been assigned above.
    focal <- remaining & iso3 %in% names(FOCAL_REGION_BY_ISO3)
    target[focal] <- unname(
      FOCAL_REGION_BY_ISO3[iso3[focal]]
    )

    eu <- is.na(target) & iso3 %in% EU27_ISO3
    target[eu] <- "EU27"

    target[is.na(target) & iso3 == "CHN"] <- "China"
    target[is.na(target) & iso3 == "USA"] <- "US"

    # countrycode's UN field may identify Latin America either at the broad
    # "Latin America and the Caribbean" level or with the narrower Caribbean /
    # Central America / South America labels, depending on the package version.
    subregion <- get_un_subregion(iso3)

    lac <- is.na(target) &
      subregion %in% c(
        "Latin America and the Caribbean",
        "Caribbean",
        "Central America",
        "South America"
      )

    target[lac] <- "RestLatAm"

    # All remaining non-direct SSP economies/territories belong to the
    # residual ROW in this 10-region MERCOSUR aggregation.
    target[is.na(target)] <- "ROW"

    method[remaining] <- "project_region_rule_for_GTAP_composite"
  }

  data.frame(
    iso3 = iso3,
    target_region = target,
    mapping_method = method,
    stringsAsFactors = FALSE
  )
}


build_country_crosswalk <- function(region_names) {

  region_names <- sort(unique(trim_chr(region_names)))

  # Remove the SSP's own R5/R9/R10/World aggregate rows BEFORE country-name
  # conversion.  Otherwise labels such as "China (R9)" can be interpreted as
  # countries by permissive name matchers and double-count the source data.
  aggregate_flag <- is_ssp_aggregate_name(region_names)

  iso3 <- rep(NA_character_, length(region_names))
  country_ix <- which(!aggregate_flag)

  iso3[country_ix] <- suppressWarnings(
    countrycode::countrycode(
      sourcevar = region_names[country_ix],
      origin = "country.name",
      destination = "iso3c",
      warn = FALSE
    )
  )

  manual_hit <- !aggregate_flag &
    region_names %in% names(manual_name_to_iso3)

  iso3[manual_hit] <- unname(
    manual_name_to_iso3[region_names[manual_hit]]
  )

  unresolved_nonaggregate <- region_names[
    is.na(iso3) & !aggregate_flag
  ]

  if (length(unresolved_nonaggregate)) {

    unresolved_file <- file.path(
      AUDIT_SSP_DIR,
      "ERROR_unrecognized_ssp_country_names.csv"
    )

    write_csv(
      data.frame(
        Region = unresolved_nonaggregate,
        stringsAsFactors = FALSE
      ),
      unresolved_file
    )

    stop(
      "Unrecognized SSP country/territory names remain after ISO conversion.\n",
      "No country is silently dropped.\nAudit:\n  ",
      unresolved_file
    )
  }

  dropped_aggregates <- data.frame(
    Region = region_names[aggregate_flag],
    reason = paste(
      "SSP supplied aggregate;",
      "country-level aggregation uses national/territorial rows only"
    ),
    stringsAsFactors = FALSE
  )

  cw <- data.frame(
    Region = region_names[!aggregate_flag],
    iso3 = toupper(iso3[!aggregate_flag]),
    stringsAsFactors = FALSE
  )

  assigned <- assign_mercosur_target(cw$iso3)

  cw$target_region <- assigned$target_region
  cw$mapping_method <- assigned$mapping_method

  # Validate every direct GTAP11 source country. Because direct countries are
  # assigned from mapr itself, any discrepancy here indicates a programming or
  # duplicate-key problem rather than a geographic classification judgement.
  direct_mapr <- mapr[!grepl("^X", mapr$source_gtap), , drop = FALSE]

  direct_assigned <- assign_mercosur_target(
    direct_mapr$source_gtap
  )

  direct_check <- data.frame(
    iso3 = direct_mapr$source_gtap,
    target_from_mapr = direct_mapr$target_region,
    target_from_calibration = direct_assigned$target_region,
    stringsAsFactors = FALSE
  )

  bad_direct <- direct_check[
    direct_check$target_from_mapr !=
      direct_check$target_from_calibration,
    ,
    drop = FALSE
  ]

  if (nrow(bad_direct)) {

    bad_file <- file.path(
      AUDIT_SSP_DIR,
      "ERROR_country_assignment_disagrees_with_mapr.csv"
    )

    write_csv(bad_direct, bad_file)

    stop(
      "Direct SSP country assignment disagrees with canonical mapr(reg,r).\n",
      "Audit:\n  ", bad_file
    )
  }

  if (!all(cw$target_region %in% EXPECTED_TARGET_REGIONS)) {
    stop("Country concordance generated an unknown target model region.")
  }

  list(
    crosswalk = cw,
    dropped_aggregates = dropped_aggregates,
    direct_validation = direct_check
  )
}

# =============================================================================
# 5. Read only the SSP series needed by this project
# =============================================================================

cat("Reading SSP Basic Drivers workbook (main data sheet)...\n")

# -------------------------------------------------------------------------
# IMPORTANT readxl typing rule
# -------------------------------------------------------------------------
#
# Do NOT let readxl guess the types of the year columns in this workbook.
# The workbook is ordered such that many early Historical Reference rows are
# blank in future years. With the default finite `guess_max`, readxl can infer
# some post-2025 year columns as LOGICAL. Later positive scenario values are
# then read as TRUE and become numeric 1 downstream. That produces the exact
# pathological pattern:
#
#   Brazil population 2030 = 1
#   Brazil GDP        2030 = 1
#   EU27 GDP          2030 = 27
#
# because TRUE values aggregate as counts.
#
# The IAMC schema is known: the first five columns are text metadata and every
# YYYY column is numeric. Read the header first and force those types explicitly.
read_iamc_sheet <- function(workbook, sheet) {

  hdr <- suppressWarnings(
    readxl::read_excel(
      workbook,
      sheet = sheet,
      n_max = 0,
      col_names = TRUE,
      .name_repair = "minimal"
    )
  )

  nm <- names(hdr)

  if (length(nm) < 6L) {
    stop(
      "Unexpected IAMC sheet width in '", sheet,
      "': found only ", length(nm), " columns."
    )
  }

  year_flag <- grepl(
    "^(19|20|21)[0-9]{2}$",
    nm
  )

  expected_meta <- c(
    "Model",
    "Scenario",
    "Region",
    "Variable",
    "Unit"
  )

  if (!identical(nm[seq_along(expected_meta)], expected_meta)) {
    stop(
      "Unexpected IAMC metadata columns in sheet '", sheet, "'.\n",
      "Expected first five columns: ",
      paste(expected_meta, collapse = " | "),
      "\nFound: ",
      paste(nm[seq_len(min(5L, length(nm)))], collapse = " | ")
    )
  }

  if (!all(year_flag[-seq_along(expected_meta)])) {
    bad <- nm[
      !year_flag &
        !(nm %in% expected_meta)
    ]

    stop(
      "Unexpected non-year column(s) after IAMC metadata in sheet '",
      sheet, "': ",
      paste(bad, collapse = " | ")
    )
  }

  col_types <- ifelse(
    year_flag,
    "numeric",
    "text"
  )

  dat <- suppressWarnings(
    readxl::read_excel(
      workbook,
      sheet = sheet,
      col_names = TRUE,
      col_types = col_types,
      .name_repair = "minimal"
    )
  )

  # Replication guard: year columns must be numeric, never logical.
  year_names <- nm[year_flag]

  bad_types <- year_names[
    !vapply(
      dat[year_names],
      is.numeric,
      logical(1)
    )
  ]

  if (length(bad_types)) {
    stop(
      "Non-numeric year column(s) after forced IAMC read in sheet '",
      sheet, "': ",
      paste(bad_types, collapse = " | ")
    )
  }

  dat
}


main_data <- read_iamc_sheet(
  SSP_WORKBOOK,
  "data"
)

turb_data <- read_iamc_sheet(
  SSP_WORKBOOK,
  "data_turbulent_economy_data"
)

required_cols <- c("Model", "Scenario", "Region", "Variable", "Unit")

if (!all(required_cols %in% names(main_data))) {
  stop(
    "Main SSP sheet schema changed. Missing columns: ",
    paste(setdiff(required_cols, names(main_data)), collapse = ", ")
  )
}

if (!all(required_cols %in% names(turb_data))) {
  stop(
    "Turbulent-economy SSP sheet schema changed. Missing columns: ",
    paste(setdiff(required_cols, names(turb_data)), collapse = ", ")
  )
}

for (nm in required_cols) {
  main_data[[nm]] <- trim_chr(main_data[[nm]])
  turb_data[[nm]] <- trim_chr(turb_data[[nm]])
}


pop_wide <- main_data[
  main_data$Model == POP_MODEL &
    main_data$Scenario %in% c("Historical Reference", TARGET_SCENARIOS) &
    main_data$Variable == POP_VARIABLE &
    main_data$Unit == POP_UNIT,
  ,
  drop = FALSE
]

gdp_main_wide <- main_data[
  main_data$Model == GDP_MODEL &
    main_data$Scenario %in% c("Historical Reference", TARGET_SCENARIOS) &
    main_data$Variable == GDP_VARIABLE &
    main_data$Unit == GDP_UNIT,
  ,
  drop = FALSE
]

gdp_turb_wide <- turb_data[
  turb_data$Model == TURB_GDP_MODEL &
    turb_data$Scenario %in% TARGET_SCENARIOS &
    turb_data$Variable == GDP_VARIABLE &
    turb_data$Unit == GDP_UNIT,
  ,
  drop = FALSE
]

rm(main_data, turb_data)
invisible(gc())


assert_unique_key(
  pop_wide,
  c("Model", "Scenario", "Region", "Variable", "Unit"),
  "SSP total population source"
)

assert_unique_key(
  gdp_main_wide,
  c("Model", "Scenario", "Region", "Variable", "Unit"),
  "SSP main GDP source"
)

assert_unique_key(
  gdp_turb_wide,
  c("Model", "Scenario", "Region", "Variable", "Unit"),
  "SSP turbulent GDP source"
)


# =============================================================================
# 6. Build and validate the country concordance
# =============================================================================

ssp_region_names <- unique(
  pop_wide$Region[
    pop_wide$Scenario %in% TARGET_SCENARIOS
  ]
)

cw_obj <- build_country_crosswalk(ssp_region_names)
country_crosswalk <- cw_obj$crosswalk
dropped_noncountry <- cw_obj$dropped_aggregates

crosswalk_file <- file.path(
  PROCESSED_SSP,
  "ssp_country_to_model_region_crosswalk.csv"
)
write_csv(country_crosswalk, crosswalk_file)

dropped_file <- file.path(
  AUDIT_SSP_DIR,
  "ssp_dropped_noncountry_regions.csv"
)
write_csv(dropped_noncountry, dropped_file)

fallback_file <- file.path(
  AUDIT_SSP_DIR,
  "ssp_mapping_fallbacks.csv"
)
write_csv(
  country_crosswalk[
    country_crosswalk$mapping_method == "project_region_rule_for_GTAP_composite",
    ,
    drop = FALSE
  ],
  fallback_file
)

direct_mapping_check_file <- file.path(
  AUDIT_SSP_DIR,
  "ssp_direct_gtap_mapping_validation.csv"
)
write_csv(
  cw_obj$direct_validation,
  direct_mapping_check_file
)

if (!identical(
  sort(unique(country_crosswalk$target_region)),
  sort(EXPECTED_TARGET_REGIONS)
)) {
  stop(
    "The country crosswalk does not populate all 10 target model regions."
  )
}


# =============================================================================
# 7. Convert selected source series to long form and keep national rows
# =============================================================================

pop_long <- wide_to_long(pop_wide, "population_million")
gdp_main_long <- wide_to_long(gdp_main_wide, "gdp_billion_usd2017_ppp")
gdp_turb_long <- wide_to_long(gdp_turb_wide, "gdp_billion_usd2017_ppp")

pop_long <- merge(
  pop_long,
  country_crosswalk,
  by = "Region",
  all = FALSE,
  sort = FALSE
)

gdp_main_long <- merge(
  gdp_main_long,
  country_crosswalk,
  by = "Region",
  all = FALSE,
  sort = FALSE
)

gdp_turb_long <- merge(
  gdp_turb_long,
  country_crosswalk,
  by = "Region",
  all = FALSE,
  sort = FALSE
)


# Historical and SSP pieces.
pop_hist <- pop_long[
  pop_long$Scenario == "Historical Reference",
  ,
  drop = FALSE
]
pop_scen <- pop_long[
  pop_long$Scenario %in% TARGET_SCENARIOS,
  ,
  drop = FALSE
]

gdp_hist <- gdp_main_long[
  gdp_main_long$Scenario == "Historical Reference",
  ,
  drop = FALSE
]

gdp_scen_main <- gdp_main_long[
  gdp_main_long$Scenario %in% TARGET_SCENARIOS,
  ,
  drop = FALSE
]

# The turbulent economies are intentionally absent from the main future GDP
# block.  Append their dedicated scenario projections.
gdp_overlap <- merge(
  unique(gdp_scen_main[c("Scenario", "Region")]),
  unique(gdp_turb_long[c("Scenario", "Region")]),
  by = c("Scenario", "Region")
)

if (nrow(gdp_overlap)) {
  overlap_file <- file.path(
    AUDIT_SSP_DIR,
    "ERROR_turbulent_gdp_duplicates_main_series.csv"
  )
  write_csv(gdp_overlap, overlap_file)

  stop(
    "Turbulent GDP records unexpectedly overlap the main future GDP block.\n",
    "Audit:\n  ", overlap_file
  )
}

gdp_scen <- rbind(
  gdp_scen_main,
  gdp_turb_long
)


# =============================================================================
# 8. Build balanced country growth bases for population and GDP
# =============================================================================

# The updated WIC population projections cover fewer countries/territories than
# the historical reference block.  Likewise, the OECD GDP source does not have
# a complete future series for every historical territory.  The model, however,
# requires regional growth rates rather than externally imposed absolute levels.
#
# Therefore:
#   1. Historical 2015 and 2020 regional levels use every country/territory with
#      valid historical values at both nodes.
#   2. Future SSP growth is calculated from a BALANCED subset of countries that
#      has valid Historical-2020 + every 2025-2050 node in BOTH SSP1 and SSP3.
#   3. The full regional 2020 historical level is then advanced using the
#      balanced-subset growth factor.
#
# This keeps the 2020 regional anchor as complete as the source allows, avoids
# dropping small historical territories from the level, and avoids inventing
# country-specific SSP projections that IIASA/OECD did not publish.
#
# For example, if B is the balanced subset and F is the full historical set:
#
#   X_region,2025 =
#       X_F,2020 * ( X_B,SSP,2025 / X_B,hist,2020 )
#
# The same logic is applied independently to population and GDP.


HIST_REQUIRED_YEARS   <- c(2015L, 2020L)
FUTURE_REQUIRED_YEARS <- seq(
  SCENARIO_START_YEAR,
  MODEL_END_YEAR,
  by = 5L
)


complete_regions_for_nodes <- function(
    df,
    value_col,
    scenario,
    required_years) {

  d <- df[
    df$Scenario == scenario &
      df$year %in% required_years &
      is.finite(df[[value_col]]) &
      df[[value_col]] > 0,
    c("Region", "year", value_col),
    drop = FALSE
  ]

  if (!nrow(d)) {
    return(character())
  }

  counts <- stats::aggregate(
    year ~ Region,
    data = unique(d[c("Region", "year")]),
    FUN = length
  )

  sort(counts$Region[
    counts$year == length(required_years)
  ])
}


sum_nodes_by_target <- function(
    df,
    value_col,
    scenario,
    years,
    regions_keep) {

  d <- df[
    df$Scenario == scenario &
      df$Region %in% regions_keep &
      df$year %in% years &
      is.finite(df[[value_col]]) &
      df[[value_col]] > 0,
    c(
      "Region",
      "target_region",
      "year",
      value_col
    ),
    drop = FALSE
  ]

  if (!nrow(d)) {
    return(data.frame())
  }

  out <- stats::aggregate(
    d[[value_col]],
    by = list(
      target_region = d$target_region,
      year = d$year
    ),
    FUN = sum
  )

  names(out)[3] <- value_col
  out$year <- as.integer(out$year)

  out
}


build_growth_basis <- function(
    hist_df,
    scen_df,
    value_col,
    variable_label) {

  hist_complete <- complete_regions_for_nodes(
    hist_df,
    value_col,
    "Historical Reference",
    HIST_REQUIRED_YEARS
  )

  ssp_complete <- lapply(
    TARGET_SCENARIOS,
    function(scen) {
      complete_regions_for_nodes(
        scen_df,
        value_col,
        scen,
        FUTURE_REQUIRED_YEARS
      )
    }
  )

  names(ssp_complete) <- TARGET_SCENARIOS

  balanced <- Reduce(
    intersect,
    c(
      list(hist_complete),
      ssp_complete
    )
  )

  if (!length(balanced)) {
    stop(
      variable_label,
      ": no countries remain in the balanced Historical/SSP1/SSP3 growth basis."
    )
  }

  all_country_rows <- unique(
    hist_df[
      hist_df$Region %in% country_crosswalk$Region,
      c("Region", "iso3", "target_region"),
      drop = FALSE
    ]
  )

  # Country-level audit flags.
  coverage_country <- all_country_rows
  coverage_country$historical_complete_2015_2020 <-
    coverage_country$Region %in% hist_complete

  for (scen in TARGET_SCENARIOS) {
    nm <- paste0(
      tolower(scen),
      "_complete_2025_2050"
    )
    coverage_country[[nm]] <-
      coverage_country$Region %in% ssp_complete[[scen]]
  }

  coverage_country$balanced_growth_basis <-
    coverage_country$Region %in% balanced

  coverage_country$variable <- variable_label

  # Historical levels with the broadest internally consistent country set.
  hist_full <- sum_nodes_by_target(
    hist_df,
    value_col,
    "Historical Reference",
    HIST_REQUIRED_YEARS,
    hist_complete
  )

  # Historical levels of the balanced future-growth subset.
  hist_bal <- sum_nodes_by_target(
    hist_df,
    value_col,
    "Historical Reference",
    c(2020L),
    balanced
  )

  names(hist_bal)[names(hist_bal) == value_col] <-
    "balanced_hist_2020"

  full_2020 <- hist_full[
    hist_full$year == 2020L,
    c("target_region", value_col),
    drop = FALSE
  ]

  names(full_2020)[2] <- "full_hist_2020"

  coverage_region <- merge(
    full_2020,
    hist_bal[c("target_region", "balanced_hist_2020")],
    by = "target_region",
    all = TRUE,
    sort = FALSE
  )

  coverage_region$coverage_share_2020 <-
    coverage_region$balanced_hist_2020 /
    coverage_region$full_hist_2020

  coverage_region$omitted_share_2020 <-
    1 - coverage_region$coverage_share_2020

  coverage_region$variable <- variable_label

  # Counts by model region.
  all_counts <- stats::aggregate(
    Region ~ target_region,
    data = all_country_rows,
    FUN = function(x) length(unique(x))
  )
  names(all_counts)[2] <- "n_source_countries"

  balanced_rows <- all_country_rows[
    all_country_rows$Region %in% balanced,
    ,
    drop = FALSE
  ]

  balanced_counts <- stats::aggregate(
    Region ~ target_region,
    data = balanced_rows,
    FUN = function(x) length(unique(x))
  )
  names(balanced_counts)[2] <- "n_balanced_countries"

  coverage_region <- merge(
    coverage_region,
    all_counts,
    by = "target_region",
    all.x = TRUE,
    sort = FALSE
  )

  coverage_region <- merge(
    coverage_region,
    balanced_counts,
    by = "target_region",
    all.x = TRUE,
    sort = FALSE
  )

  coverage_region$n_balanced_countries[
    is.na(coverage_region$n_balanced_countries)
  ] <- 0L

  # Every target region must have a positive balanced 2020 anchor.
  bad_anchor <- coverage_region[
    !is.finite(coverage_region$balanced_hist_2020) |
      coverage_region$balanced_hist_2020 <= 0 |
      !is.finite(coverage_region$full_hist_2020) |
      coverage_region$full_hist_2020 <= 0,
    ,
    drop = FALSE
  ]

  if (nrow(bad_anchor)) {
    bad_file <- file.path(
      AUDIT_SSP_DIR,
      paste0(
        "ERROR_", tolower(variable_label),
        "_growth_basis_anchor.csv"
      )
    )
    write_csv(bad_anchor, bad_file)

    stop(
      variable_label,
      ": at least one model region has no valid 2020 growth-basis anchor.\n",
      "Audit:\n  ", bad_file
    )
  }

  # Warn, but do not fail yet, when the balanced subset represents less than
  # 95% of the historical regional level.  We inspect this empirically before
  # deciding whether a hard final-replication threshold is warranted.
  low_cov <- coverage_region[
    is.finite(coverage_region$coverage_share_2020) &
      coverage_region$coverage_share_2020 < 0.95,
    ,
    drop = FALSE
  ]

  if (nrow(low_cov)) {
    warning(
      variable_label,
      ": balanced SSP growth basis covers less than 95% of the 2020 ",
      "historical source level in at least one model region. ",
      "See ssp_growth_basis_coverage.csv."
    )
  }

  list(
    hist_full = hist_full,
    hist_bal = hist_bal,
    balanced_regions = balanced,
    country_coverage = coverage_country,
    region_coverage = coverage_region
  )
}


pop_basis <- build_growth_basis(
  hist_df = pop_hist,
  scen_df = pop_scen,
  value_col = "population_million",
  variable_label = "Population"
)

gdp_basis <- build_growth_basis(
  hist_df = gdp_hist,
  scen_df = gdp_scen,
  value_col = "gdp_billion_usd2017_ppp",
  variable_label = "GDP"
)


# =============================================================================
# 9. Construct complete 10-region source-node paths
# =============================================================================

construct_region_nodes <- function(
    hist_df,
    scen_df,
    basis,
    value_col,
    variable_label) {

  hist_nodes <- basis$hist_full
  balanced <- basis$balanced_regions

  full_2020 <- hist_nodes[
    hist_nodes$year == 2020L,
    c("target_region", value_col),
    drop = FALSE
  ]
  names(full_2020)[2] <- "full_hist_2020"

  bal_hist_2020 <- basis$hist_bal[
    ,
    c("target_region", "balanced_hist_2020"),
    drop = FALSE
  ]

  anchor <- merge(
    full_2020,
    bal_hist_2020,
    by = "target_region",
    all = TRUE,
    sort = FALSE
  )

  pieces <- list()
  k <- 0L

  for (scen in TARGET_SCENARIOS) {

    future_bal <- sum_nodes_by_target(
      scen_df,
      value_col,
      scen,
      FUTURE_REQUIRED_YEARS,
      balanced
    )

    future_bal <- merge(
      future_bal,
      anchor,
      by = "target_region",
      all.x = TRUE,
      sort = FALSE
    )

    future_bal[[value_col]] <-
      future_bal$full_hist_2020 *
      future_bal[[value_col]] /
      future_bal$balanced_hist_2020

    future_bal$Scenario <- scen

    historical <- hist_nodes
    historical$Scenario <- scen

    combined <- rbind(
      historical[
        historical$year %in% HIST_REQUIRED_YEARS,
        c(
          "Scenario",
          "target_region",
          "year",
          value_col
        ),
        drop = FALSE
      ],
      future_bal[
        ,
        c(
          "Scenario",
          "target_region",
          "year",
          value_col
        ),
        drop = FALSE
      ]
    )

    combined$variable <- variable_label

    k <- k + 1L
    pieces[[k]] <- combined
  }

  nodes <- do.call(rbind, pieces)

  nodes <- nodes[
    order(
      nodes$Scenario,
      match(nodes$target_region, EXPECTED_TARGET_REGIONS),
      nodes$year
    ),
    ,
    drop = FALSE
  ]

  nodes
}


pop_nodes <- construct_region_nodes(
  hist_df = pop_hist,
  scen_df = pop_scen,
  basis = pop_basis,
  value_col = "population_million",
  variable_label = "Population"
)

gdp_nodes <- construct_region_nodes(
  hist_df = gdp_hist,
  scen_df = gdp_scen,
  basis = gdp_basis,
  value_col = "gdp_billion_usd2017_ppp",
  variable_label = "GDP"
)


# =============================================================================
# 10. Annualize the 10 regional paths: 2017-2050
# =============================================================================

annualize_region_nodes <- function(
    nodes,
    value_col) {

  pieces <- list()
  k <- 0L

  for (scen in TARGET_SCENARIOS) {
    for (reg in EXPECTED_TARGET_REGIONS) {

      d <- nodes[
        nodes$Scenario == scen &
          nodes$target_region == reg,
        c("year", value_col),
        drop = FALSE
      ]

      d <- d[
        is.finite(d[[value_col]]) &
          d[[value_col]] > 0,
        ,
        drop = FALSE
      ]

      d <- d[order(d$year), , drop = FALSE]

      if (
        !all(c(2015L, 2020L, 2025L, 2050L) %in% d$year) ||
        min(d$year) > 2015L ||
        max(d$year) < MODEL_END_YEAR
      ) {
        stop(
          "Incomplete regional node path for ",
          scen, " / ", reg, " / ", value_col
        )
      }

      annual <- stats::approx(
        x = d$year,
        y = log(d[[value_col]]),
        xout = MODEL_YEARS,
        method = "linear",
        rule = 1,
        ties = "ordered"
      )$y

      if (any(!is.finite(annual))) {
        stop(
          "Annual interpolation failed for ",
          scen, " / ", reg, " / ", value_col
        )
      }

      k <- k + 1L
      pieces[[k]] <- data.frame(
        Scenario = scen,
        target_region = reg,
        year = MODEL_YEARS,
        value = exp(annual),
        stringsAsFactors = FALSE
      )
    }
  }

  out <- do.call(rbind, pieces)
  names(out)[names(out) == "value"] <- value_col
  out
}


pop_region <- annualize_region_nodes(
  pop_nodes,
  "population_million"
)

gdp_region <- annualize_region_nodes(
  gdp_nodes,
  "gdp_billion_usd2017_ppp"
)

region_annual <- merge(
  pop_region,
  gdp_region,
  by = c(
    "Scenario",
    "target_region",
    "year"
  ),
  all = TRUE,
  sort = FALSE
)

region_annual <- region_annual[
  order(
    region_annual$Scenario,
    match(
      region_annual$target_region,
      EXPECTED_TARGET_REGIONS
    ),
    region_annual$year
  ),
  ,
  drop = FALSE
]

expected_rows <- length(TARGET_SCENARIOS) *
  length(EXPECTED_TARGET_REGIONS) *
  length(MODEL_YEARS)

if (nrow(region_annual) != expected_rows) {
  stop(
    "Unexpected number of scenario x model-region x year rows. Expected ",
    expected_rows, ", found ", nrow(region_annual), "."
  )
}

if (
  any(!is.finite(region_annual$population_million)) ||
  any(region_annual$population_million <= 0) ||
  any(!is.finite(
    region_annual$gdp_billion_usd2017_ppp
  )) ||
  any(region_annual$gdp_billion_usd2017_ppp <= 0)
) {
  stop(
    "Invalid population or GDP level in the 10-region annual panel."
  )
}

# Source-corruption sentinel for this fixed 10-region aggregation.
# Every model region contains well above one million people and more than one
# billion 2017-PPP dollars of GDP throughout 2017-2050. Values at or below 1
# therefore indicate a parsing/type error, not a plausible SSP trajectory.
bad_level <- region_annual[
  region_annual$population_million <= 1 |
    region_annual$gdp_billion_usd2017_ppp <= 1,
  ,
  drop = FALSE
]

if (nrow(bad_level)) {

  bad_file <- file.path(
    AUDIT_SSP_DIR,
    "ERROR_implausible_regional_levels.csv"
  )

  write_csv(
    bad_level,
    bad_file
  )

  stop(
    "Implausible regional SSP levels detected (<= 1). ",
    "This usually indicates a source-column typing/parsing error.\n",
    "Audit:\n  ",
    bad_file
  )
}


# =============================================================================
# 11. Smooth the 2017-2025 baseline bridge
# =============================================================================
#
# The GTAP benchmark is 2017.  We are building a forward-looking SSP baseline,
# not attempting to reproduce the realized 2018-2020 recession/COVID path.
#
# The Historical Reference series contains negative GDP-per-capita growth for
# several regions between 2017 and 2020. Feeding those realized contractions
# into DynCal forces negative labor-productivity calibration and permanently
# affects the subsequent recursive capital/productivity path.
#
# Instead, preserve the two economically relevant anchors:
#   - 2017 Historical Reference level (growth anchor for the GTAP base);
#   - 2025 SSP scenario level (first future SSP node).
#
# Population and GDP are each log-linearly interpolated from 2017 to 2025.
# This gives a constant compound bridge over 2018-2025 while preserving both
# endpoint levels exactly.  From 2025 onward the original SSP annualized path
# is left unchanged.
#
# IMPORTANT: this is not a zero-floor on ggdppc.  Zero-flooring negative years
# would change the cumulative 2025 target.  The bridge re-distributes growth
# over 2017-2025 while preserving the 2025 SSP population and GDP anchors.

BRIDGE_END_YEAR <- 2025L

region_annual$population_million_source_path <-
  region_annual$population_million

region_annual$gdp_billion_usd2017_ppp_source_path <-
  region_annual$gdp_billion_usd2017_ppp

region_annual$baseline_bridge_applied <- FALSE

for (scen in TARGET_SCENARIOS) {
  for (reg in EXPECTED_TARGET_REGIONS) {

    ix17 <- which(
      region_annual$Scenario == scen &
        region_annual$target_region == reg &
        region_annual$year == BASE_YEAR
    )

    ix25 <- which(
      region_annual$Scenario == scen &
        region_annual$target_region == reg &
        region_annual$year == BRIDGE_END_YEAR
    )

    if (length(ix17) != 1L || length(ix25) != 1L) {
      stop(
        "Could not identify unique 2017/2025 bridge anchors for ",
        scen, " / ", reg
      )
    }

    p17 <- region_annual$population_million[ix17]
    p25 <- region_annual$population_million[ix25]
    y17 <- region_annual$gdp_billion_usd2017_ppp[ix17]
    y25 <- region_annual$gdp_billion_usd2017_ppp[ix25]

    if (
      any(!is.finite(c(p17, p25, y17, y25))) ||
      any(c(p17, p25, y17, y25) <= 0)
    ) {
      stop(
        "Invalid 2017/2025 bridge anchor for ",
        scen, " / ", reg
      )
    }

    ix_bridge <- which(
      region_annual$Scenario == scen &
        region_annual$target_region == reg &
        region_annual$year > BASE_YEAR &
        region_annual$year < BRIDGE_END_YEAR
    )

    if (length(ix_bridge)) {

      w <- (
        region_annual$year[ix_bridge] - BASE_YEAR
      ) / (
        BRIDGE_END_YEAR - BASE_YEAR
      )

      region_annual$population_million[ix_bridge] <-
        exp(
          log(p17) +
            w * (log(p25) - log(p17))
        )

      region_annual$gdp_billion_usd2017_ppp[ix_bridge] <-
        exp(
          log(y17) +
            w * (log(y25) - log(y17))
        )

      region_annual$baseline_bridge_applied[ix_bridge] <- TRUE
    }
  }
}


# =============================================================================
# 12. Derive model-ready annual growth objects
# =============================================================================

region_annual$gdp_pc_usd2017_ppp <-
  1000 *
  region_annual$gdp_billion_usd2017_ppp /
  region_annual$population_million

region_annual$population_index_2017 <- NA_real_
region_annual$population_growth <- NA_real_
region_annual$gdp_growth <- NA_real_
region_annual$ggdppc_target <- NA_real_
region_annual$aft_labor_index_2017 <- NA_real_

for (scen in TARGET_SCENARIOS) {
  for (reg in EXPECTED_TARGET_REGIONS) {

    ix <- which(
      region_annual$Scenario == scen &
        region_annual$target_region == reg
    )

    ix <- ix[
      order(region_annual$year[ix])
    ]

    if (length(ix) != length(MODEL_YEARS)) {
      stop(
        "Incomplete annual series for ",
        scen, " / ", reg
      )
    }

    pop <- region_annual$population_million[ix]
    gdp <- region_annual$gdp_billion_usd2017_ppp[ix]
    pc  <- region_annual$gdp_pc_usd2017_ppp[ix]

    pop_growth <- c(
      1,
      pop[-1] / pop[-length(pop)]
    )

    gdp_growth <- c(
      1,
      gdp[-1] / gdp[-length(gdp)]
    )

    pc_growth <- c(
      0,
      pc[-1] / pc[-length(pc)] - 1
    )

    pop_index <- pop / pop[1]

    region_annual$population_index_2017[ix] <-
      pop_index

    region_annual$aft_labor_index_2017[ix] <-
      pop_index

    region_annual$population_growth[ix] <-
      pop_growth

    region_annual$gdp_growth[ix] <-
      gdp_growth

    region_annual$ggdppc_target[ix] <-
      pc_growth
  }
}


# Core identity used by iterloop.gms with annual gap(t)=1:
#
#   (1 + ggdppc_target_t) * POP_t/POP_{t-1}
#          = GDP_t/GDP_{t-1}
#
identity_lhs <-
  (1 + region_annual$ggdppc_target) *
  region_annual$population_growth

identity_error <-
  abs(
    identity_lhs -
      region_annual$gdp_growth
  )

identity_error[
  region_annual$year == BASE_YEAR
] <- 0

max_identity_error <-
  max(identity_error, na.rm = TRUE)

if (
  !is.finite(max_identity_error) ||
  max_identity_error > 1e-9
) {
  stop(
    "GDP growth decomposition identity failed. ",
    "Max absolute error = ",
    format(
      max_identity_error,
      scientific = TRUE
    )
  )
}


# =============================================================================
# 13. Growth-basis coverage diagnostics
# =============================================================================

country_growth_coverage <- rbind(
  pop_basis$country_coverage,
  gdp_basis$country_coverage
)

country_growth_coverage <- country_growth_coverage[
  order(
    country_growth_coverage$variable,
    country_growth_coverage$target_region,
    country_growth_coverage$iso3
  ),
  ,
  drop = FALSE
]

growth_basis_coverage <- rbind(
  pop_basis$region_coverage,
  gdp_basis$region_coverage
)

growth_basis_coverage <- growth_basis_coverage[
  order(
    growth_basis_coverage$variable,
    match(
      growth_basis_coverage$target_region,
      EXPECTED_TARGET_REGIONS
    )
  ),
  ,
  drop = FALSE
]

growth_basis_exclusions <-
  country_growth_coverage[
    !country_growth_coverage$balanced_growth_basis,
    ,
    drop = FALSE
  ]

# Negative GDP-per-capita growth is economically admissible.  Do not truncate
# or replace it.  Keep an explicit audit so historical contractions and any
# projected contractions can be inspected before DynCal.
negative_ggdppc_targets <- region_annual[
  region_annual$year > BASE_YEAR &
    region_annual$ggdppc_target < 0,
  c(
    "Scenario",
    "target_region",
    "year",
    "population_million",
    "gdp_billion_usd2017_ppp",
    "gdp_pc_usd2017_ppp",
    "population_growth",
    "gdp_growth",
    "ggdppc_target"
  ),
  drop = FALSE
]

negative_ggdppc_targets$source_period <- ifelse(
  negative_ggdppc_targets$year <= HISTORICAL_END_YEAR,
  "historical_reference",
  "ssp_transition_or_projection"
)

negative_ggdppc_count <- nrow(
  negative_ggdppc_targets
)

negative_ggdppc_post2020_count <- sum(
  negative_ggdppc_targets$year > HISTORICAL_END_YEAR
)

minimum_ggdppc_target <- if (
  negative_ggdppc_count > 0
) {
  min(
    negative_ggdppc_targets$ggdppc_target,
    na.rm = TRUE
  )
} else {
  0
}

min_population_growth_basis_share <-
  min(
    growth_basis_coverage$coverage_share_2020[
      growth_basis_coverage$variable == "Population"
    ],
    na.rm = TRUE
  )

min_gdp_growth_basis_share <-
  min(
    growth_basis_coverage$coverage_share_2020[
      growth_basis_coverage$variable == "GDP"
    ],
    na.rm = TRUE
  )


# =============================================================================
# 14. Write processed SSP datasets and audits
# =============================================================================

country_coverage_file <- file.path(
  PROCESSED_SSP,
  "ssp_country_growth_basis_coverage.csv"
)

region_annual_file <- file.path(
  PROCESSED_SSP,
  paste0(
    "ssp_model_region_annual_",
    BASE_YEAR, "_", MODEL_END_YEAR,
    ".csv"
  )
)

growth_basis_coverage_file <- file.path(
  AUDIT_SSP_DIR,
  "ssp_growth_basis_coverage.csv"
)

growth_basis_exclusions_file <- file.path(
  AUDIT_SSP_DIR,
  "ssp_growth_basis_exclusions.csv"
)

negative_ggdppc_file <- file.path(
  AUDIT_SSP_DIR,
  "ssp_negative_ggdppc_targets.csv"
)

write_csv(
  country_growth_coverage,
  country_coverage_file
)

write_csv(
  region_annual,
  region_annual_file
)

write_csv(
  growth_basis_coverage,
  growth_basis_coverage_file
)

write_csv(
  growth_basis_exclusions,
  growth_basis_exclusions_file
)

write_csv(
  negative_ggdppc_targets,
  negative_ggdppc_file
)


# =============================================================================
# 15. Write model-ready SSP .inc files
# =============================================================================

format_gams_number <- function(x) {
  if (!is.finite(x)) {
    stop("Attempt to write a non-finite value to GAMS include.")
  }

  # Enough precision for annual growth factors without producing noisy strings.
  formatC(x, digits = 12, format = "fg", flag = "#")
}


write_ssp_inc <- function(scenario, data, path) {

  d <- data[
    data$Scenario == scenario,
    ,
    drop = FALSE
  ]

  d <- d[
    order(
      match(d$target_region, EXPECTED_TARGET_REGIONS),
      d$year
    ),
    ,
    drop = FALSE
  ]

  con <- file(path, open = "wt", encoding = "UTF-8")
  on.exit(close(con), add = TRUE)

  writeLines(
    c(
      "* ============================================================================",
      "* GENERATED FILE — DO NOT EDIT BY HAND",
      paste0("* Source script: calibration/scripts/02_build_calibration_inputs.R"),
      paste0("* SSP scenario: ", scenario),
      paste0("* Model years: ", BASE_YEAR, "-", MODEL_END_YEAR),
      "*",
      "* Intended use:",
      "*   Include AFTER cal.gms in a dedicated DynCal or counterfactual launcher.",
      "*   The launcher time set must contain every year written below.",
      "*",
      "* Economic interpretation:",
      "*   - pop.fx follows SSP population growth from the normalized GTAP 2017 base.",
      "*   - aft(r,l,t) follows the same population growth for both labor factors.",
      "*   - ggdppc.fx is fixed directly to the annual SSP real GDP-per-capita growth target.",
      "*   - the model parameter ggdppcT is deliberately NOT modified by this include.",
      "*   - absolute SSP GDP/population levels do NOT replace GTAP 2017 levels.",
      "* ============================================================================",
      ""
    ),
    con
  )

  for (reg in EXPECTED_TARGET_REGIONS) {

    dr <- d[d$target_region == reg, , drop = FALSE]
    dr <- dr[order(dr$year), , drop = FALSE]

    writeLines(
      paste0("* --- ", reg, " ---"),
      con
    )

    for (j in 2:nrow(dr)) {

      yr <- dr$year[j]
      prev <- dr$year[j - 1L]

      pg <- dr$population_growth[j]
      gy <- dr$ggdppc_target[j]

      writeLines(
        c(
          paste0(
            "pop.fx(\"", reg, "\",\"", yr, "\") = ",
            "pop.l(\"", reg, "\",\"", prev, "\") * ",
            format_gams_number(pg), ";"
          ),
          paste0(
            "aft(\"", reg, "\",l,\"", yr, "\") = ",
            "aft(\"", reg, "\",l,\"", prev, "\") * ",
            format_gams_number(pg), ";"
          ),
          paste0(
            "ggdppc.fx(\"", reg, "\",\"", yr, "\") = ",
            format_gams_number(gy), ";"
          )
        ),
        con
      )
    }

    writeLines("", con)
  }

  close(con)
  on.exit(NULL, add = FALSE)
}


inc_files <- character()

for (scen in TARGET_SCENARIOS) {

  inc_name <- paste0(
    tolower(scen),
    "_socioeconomic_",
    BASE_YEAR, "_", MODEL_END_YEAR,
    ".inc"
  )

  inc_path <- file.path(OUTPUT_INC_DIR, inc_name)

  write_ssp_inc(
    scenario = scen,
    data = region_annual,
    path = inc_path
  )

  inc_files <- c(inc_files, inc_path)
}


# =============================================================================
# 16. Validation summary
# =============================================================================

scenario_start_check <- region_annual[
  region_annual$year %in% c(
    BASE_YEAR,
    HISTORICAL_END_YEAR,
    SCENARIO_START_YEAR,
    2030L,
    2050L
  ),
  c(
    "Scenario",
    "target_region",
    "year",
    "population_million",
    "gdp_billion_usd2017_ppp",
    "population_growth",
    "ggdppc_target",
    "gdp_growth"
  ),
  drop = FALSE
]

validation_summary <- data.frame(
  check = c(
    "canonical_mapr_source_regions",
    "target_model_regions",
    "mapped_ssp_countries_or_territories",
    "project_rule_for_gtap_composite_rows",
    "dropped_ssp_aggregate_rows",
    "population_balanced_growth_basis_countries",
    "gdp_balanced_growth_basis_countries",
    "minimum_population_growth_basis_share_2020",
    "minimum_gdp_growth_basis_share_2020",
    "baseline_bridge_end_year",
    "negative_ggdppc_target_years",
    "negative_ggdppc_target_years_after_2020",
    "minimum_ggdppc_target",
    "annual_model_years",
    "max_gdp_decomposition_error"
  ),
  value = c(
    as.character(nrow(mapr)),
    as.character(length(EXPECTED_TARGET_REGIONS)),
    as.character(nrow(country_crosswalk)),
    as.character(sum(
      country_crosswalk$mapping_method ==
        "project_region_rule_for_GTAP_composite"
    )),
    as.character(nrow(dropped_noncountry)),
    as.character(length(
      pop_basis$balanced_regions
    )),
    as.character(length(
      gdp_basis$balanced_regions
    )),
    format(
      min_population_growth_basis_share,
      scientific = FALSE,
      digits = 8
    ),
    format(
      min_gdp_growth_basis_share,
      scientific = FALSE,
      digits = 8
    ),
    as.character(
      BRIDGE_END_YEAR
    ),
    as.character(
      negative_ggdppc_count
    ),
    as.character(
      negative_ggdppc_post2020_count
    ),
    format(
      minimum_ggdppc_target,
      scientific = FALSE,
      digits = 8
    ),
    as.character(length(MODEL_YEARS)),
    format(
      max_identity_error,
      scientific = TRUE,
      digits = 6
    )
  ),
  stringsAsFactors = FALSE
)

validation_file <- file.path(
  AUDIT_SSP_DIR,
  "ssp_validation_summary.csv"
)

write_csv(
  validation_summary,
  validation_file
)

scenario_check_file <- file.path(
  AUDIT_SSP_DIR,
  "ssp_selected_years_check.csv"
)

write_csv(
  scenario_start_check,
  scenario_check_file
)


# =============================================================================
# 17. Reserved later calibration modules
# =============================================================================

# -----------------------------------------------------------------------------
# Task 5 — GAEZ v5 crop yields -> lndtfp(r,a,t)
# -----------------------------------------------------------------------------
# This section will be implemented in THIS SAME canonical build script.
# No permanent standalone GAEZ-processing script should be created unless a
# source-format constraint makes that unavoidable.
#
# Required final outputs will be written under:
#   calibration/processed/gaez/
#   calibration/output/inc/
#   calibration/audit/gaez/
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Task 6/7 — Trade_Barrier_Inputs_2019_2050.xlsx -> policy shock paths
# -----------------------------------------------------------------------------
# This section will also be implemented in THIS SAME canonical build script
# after the trade workbook has been audited.
#
# Required final outputs will be written under:
#   calibration/processed/trade/
#   calibration/output/inc/
#   calibration/audit/trade/
# -----------------------------------------------------------------------------


# =============================================================================
# 18. Generic run summary
# =============================================================================

cat("\n")
cat("====================================================================================================\n")
cat("SUMMARY\n")
cat("====================================================================================================\n")

cat(
  "project_root: ",
  PROJECT_ROOT,
  "\n",
  sep = ""
)

cat(
  "ssp_workbook: ",
  SSP_WORKBOOK,
  "\n",
  sep = ""
)

cat(
  "agggtap_file: ",
  AGGGTAP_FILE,
  "\n",
  sep = ""
)

cat(
  "agggtap_aggregation_macro: ",
  ifelse(
    is.na(AGGGTAP_AGGREGATION_MACRO),
    "(not found)",
    AGGGTAP_AGGREGATION_MACRO
  ),
  "\n",
  sep = ""
)

cat(
  "mapping_file: ",
  MAPPING_FILE,
  "\n",
  sep = ""
)

cat(
  "scenarios: ",
  paste(
    TARGET_SCENARIOS,
    collapse = " | "
  ),
  "\n",
  sep = ""
)

cat(
  "model_years: ",
  BASE_YEAR, "-", MODEL_END_YEAR,
  "\n",
  sep = ""
)

cat(
  "target_regions: ",
  length(EXPECTED_TARGET_REGIONS),
  "\n",
  sep = ""
)

cat(
  "mapped_countries_or_territories: ",
  nrow(country_crosswalk),
  "\n",
  sep = ""
)

cat(
  "population_balanced_growth_basis_countries: ",
  length(pop_basis$balanced_regions),
  "\n",
  sep = ""
)

cat(
  "gdp_balanced_growth_basis_countries: ",
  length(gdp_basis$balanced_regions),
  "\n",
  sep = ""
)

cat(
  "minimum_population_growth_basis_share_2020: ",
  format(
    min_population_growth_basis_share,
    digits = 8
  ),
  "\n",
  sep = ""
)

cat(
  "minimum_gdp_growth_basis_share_2020: ",
  format(
    min_gdp_growth_basis_share,
    digits = 8
  ),
  "\n",
  sep = ""
)

cat(
  "baseline_bridge: ",
  BASE_YEAR, "->", BRIDGE_END_YEAR,
  " log-linear population + GDP",
  "\n",
  sep = ""
)

cat(
  "negative_ggdppc_target_years: ",
  negative_ggdppc_count,
  "\n",
  sep = ""
)

cat(
  "negative_ggdppc_target_years_after_2020: ",
  negative_ggdppc_post2020_count,
  "\n",
  sep = ""
)

cat(
  "minimum_ggdppc_target: ",
  format(
    minimum_ggdppc_target,
    digits = 8
  ),
  "\n",
  sep = ""
)

cat(
  "max_gdp_decomposition_error: ",
  format(
    max_identity_error,
    scientific = TRUE,
    digits = 6
  ),
  "\n",
  sep = ""
)

cat(
  "processed_region_panel: ",
  region_annual_file,
  "\n",
  sep = ""
)

cat(
  "country_growth_basis_coverage: ",
  country_coverage_file,
  "\n",
  sep = ""
)

cat(
  "growth_basis_coverage_audit: ",
  growth_basis_coverage_file,
  "\n",
  sep = ""
)

cat(
  "growth_basis_exclusions_audit: ",
  growth_basis_exclusions_file,
  "\n",
  sep = ""
)

cat(
  "negative_ggdppc_audit: ",
  negative_ggdppc_file,
  "\n",
  sep = ""
)

cat(
  "crosswalk: ",
  crosswalk_file,
  "\n",
  sep = ""
)

cat(
  "direct_mapping_validation: ",
  direct_mapping_check_file,
  "\n",
  sep = ""
)

cat(
  "validation_summary: ",
  validation_file,
  "\n",
  sep = ""
)

cat("gams_includes:\n")

for (p in inc_files) {
  cat(
    "  - ",
    p,
    "\n",
    sep = ""
  )
}

cat("====================================================================================================\n")
