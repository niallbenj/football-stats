#' @title Analyse Match and Event and Predict
#'
#' @description A function that analyses matches and events only,
#'  then straight after makes match predictions based on the competition,
#'  this is to be run as a CRON job in deployment.
#'
#' @param deployed A boolean value to indicate whether the
#'  function is being run from a deployed environment.
#'
#' @return Nothing. Redis is updated.
#'
#' @importFrom magrittr %>% %<>% %T>% %$%
#'
#' @export


analyse_and_predict <- function(deployed = FALSE, addAll = TRUE,
                                cMethods = c("xgboost", "neuralnetwork"),
                                predRange = c(1, 7)) { # nocov start

  # Obtain API and sensitive key information
  KEYS <- footballstats::sensitive_keys(
    printToSlack = TRUE,
    printToScreen = FALSE,
    testing = FALSE,
    storePred = TRUE
  )

  # Load competitions and run the functionality below.
  competitions <- KEYS %>% footballstats::acomp_info()

  # Subset the available competitions
  competitions %<>% subset(competitions$id %in% footballstats::allowed_comps())

  # Create the sink for adding data
  if (deployed) 'summary_predictions' %>% footballstats::create_sink()

  # Loop over all competitions being analysed
  for (i in 1:nrow(competitions)) {
    cat(
      " ## Storing ::" , i, "/", nrow(competitions), "(",
      competitions$name[i], "-", competitions$region[i], " ["
    )

    # Append the appropriate competition information to KEYS
    KEYS$COMP <- competitions$id[i]
    KEYS$TIL <- KEYS$COMP %>% footballstats::teams_in_league()

    # Get the dates and seasons from yaml file
    KEYS %<>% footballstats::dates_from_yaml()

    # Look for matches ~ 2 weeks in the past
    KEYS$DATE_FROM <- Sys.Date() %>% `-`(14) %>% footballstats::format_dates()
    KEYS$DATE_TO <- Sys.Date() %>% footballstats::format_dates()

    # Only add data if it is within the season window
    if (KEYS$ACTIVE && addAll) {
      cat(" ACTIVE ] ).\n")
      KEYS %>% footballstats::add_all()
    } else {
      cat(" INACTIVE ).\n")
    }
  }

  # --- Make sure any new stats haven't been added since last call -- #
  KEYS %>% footballstats::stats_from_yaml()

  # --- Now predict matches --- #
  cat('\n\n *** Beginning predictions *** \n\n')

  if (predRange[1] >= predRange[2]) stop("Prediction range is invalid")
  KEYS$DATE_FROM <- Sys.Date() %>% `+`(predRange[1]) %>% footballstats::format_dates()
  KEYS$DATE_TO <- Sys.Date() %>% `+`(predRange[2]) %>% footballstats::format_dates()

  # Loop over each classification type
  for (k in 1:(cMethods %>% length)) {

    # Rest total predictions each time
    totalPredictions <- 0

    # Load the appropriate data model
    cat(paste0(Sys.time(), " | Loading data model ... \n"))
    datModel <- if (cMethods[k] == "xgboost") {
      footballstats::xgModel
    } else if (cMethods[k] == "neuralnetwork") {
      footballstats::nnModel
    } else {
      stop(" ## Select a valid value for cMethod!")
    }

    # Loop over each competition
    for (i in 1:nrow(competitions)) {
      cat(
        paste0(
          Sys.time(), ' | Storing ' , i, ' / ', nrow(competitions), ' (',
          competitions$name[i], ' - ', competitions$region[i], '). \n'
        )
      )

      # Predict actual future results
      KEYS$COMP <- competitions$id[i]
      KEYS$TIL <- KEYS$COMP %>% footballstats::teams_in_league()
      KEYS$COMP_NAME <- competitions$name[i]

      cat(paste0(Sys.time(), ' | Predicting actual upcoming fixtures. \n'))
      predictions <- KEYS %>%
        footballstats::predict_matches(
          datModel = datModel,
          cMethod = cMethods[k]
        )
      totalPredictions %<>% `+`(predictions)

      # Send a slack message to indicate how many matches have been predicted
      if (KEYS$SLACK_PRNT && i == nrow(competitions)) {
        slackr::slackrSetup(
          channel = '#results',
          api_token = KEYS$FS_SLACK
        )
        slackr::slackr_msg(
          txt = paste0('Predicted a total of ', totalPredictions, ' matches'),
          channel = '#results',
          api_token = KEYS$FS_SLACK,
          username = 'predictions'
        )
      }
    }
  }
} # nocov end

#' @title Analyse Players
#'
#' @description A function that analyses players only,
#'  this is to be run as a CRON job in deployment.
#'
#' @details Redis Keys used;
#'   \itemize{
#'     \item{\strong{[LIST]} :: \code{analysePlayers}}
#'   }
#'
#' @param deployed A boolean value to indicate whether the
#'  function is being run from a deployed environment.
#'
#' @return Nothing. Redis is updated.
#'
#' @export


analyse_players <- function(deployed = FALSE) { # nocov start
  # Obtain API and sensitive key information
  KEYS <- footballstats::sensitive_keys(
    printToSlack = TRUE,
    printToScreen = FALSE,
    testing = FALSE,
    storePred = TRUE
  )

  # Store additional KEY information
  KEYS$SEASON <- footballstats::start_season()

  # Create the sink for output
  if (deployed) 'summary_players' %>% footballstats::create_sink()

  # Add player information
  playerLength <- 'analysePlayers' %>% KEYS$RED$LLEN()
  if (playerLength > 0) {
    cat(paste(' ## Analysing a total of ', playerLength, ' unique players. \n'))
    tNow <- Sys.time()
    KEYS %>% footballstats::aplayer_info(
      playerLength = playerLength
    )
    cat(' ## Players analysed with a \n')
    cat(paste(' ## ', Sys.time() - tNow))
  }

  # Only complete - delete the analysePlayers key (if it exists..)
  if ("analysePlayers" %>% KEYS$RED$EXISTS() %>% as.logical) "analysePlayers" %>% KEYS$RED$DEL()

} # nocov end

#' @title Send Report
#'
#' @description A function to send a monthly report
#'
#' @return Nothing. Redis is updated.
#'
#' @export


send_report <- function(KEYS) { # nocov start

  # Not sure I can properly get the year...
  # ...

  # Get the month and year for LAST month (i.e. the report to be created)
  month <- Sys.Date() %>% `-`(30) %>% format('%m') %>% as.integer
  Sys.Date() %>% footballstats::prs_season()
  #year <- Sys.Date() %>% `-`(30) %>% format('%Y') %>% as.integer

} # nocov end
