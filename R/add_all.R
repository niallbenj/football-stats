#' @title Add All Information
#'
#' @description A function that is called from a shell script to kick off
#'  the storing of important data and also any machine learning mechanisms
#'  for prediction.
#'
#' @details This main function is split into 3 main important components
#'  \itemize{
#'    \item{
#'      All libraries, global variables are loaded. Storing mechanisms
#'      that incorporate new ID keys are generated to store all useful
#'      information for classification / algorithms.
#'    }
#'    \item{
#'      Statistical models are built on the stored data and redis, future
#'      fixtures are obtained and built into the models.
#'    }
#'    \item{
#'      Predictions are made based on the current data and models and
#'      anything useful is sent via slack for easy analysis.
#'    }
#'  }
#'
#' @param KEYS A list containing options such as testing / prediction /
#'  important variables and information. Also contains API information.
#'
#' @return Returns nothing.
#'
#' @export


add_all <- function(KEYS) { # nocov start

  # Lookup request timings
  startingRequests <- "requestLimit" %>% KEYS$RED$GET() %>% as.integer
  startingTime <- "requestLimit" %>% KEYS$RED$TTL()

  # Add match information and order it
  cat(paste0(Sys.time(), ' | Matches ...'))
  matches <- KEYS %>%
    footballstats::amatch_info()
  cat(' complete \n')

  # Order match data + perform other operations if any data exists
  if (matches %>% nrow %>% `>`(0)) {
    matches %<>% footballstats::order_matchdata()

    # Build league table
    cat(paste0(Sys.time(), ' | Creating the league table ... \n'))
    KEYS %>% footballstats::create_table(
      matchData = matches
    )

    # Store positions on a weekly basis
    cat(paste0(Sys.time(), ' | Storing weekly positions ... \n'))
    KEYS %>% footballstats::weekly_positions()
  }

  # Store predicted vs. real outcomes
  readyToAnalyse <- paste0('csdm_pred:', KEYS$COMP, ':', KEYS$SEASON, ':*') %>%
    KEYS$RED$KEYS()

  if (readyToAnalyse %>% length %>% `>`(0)) {
    KEYS %>% footballstats::predict_vs_real(
      readyToAnalyse = readyToAnalyse %>% purrr::flatten_chr(),
      matches = matches
    )
  }

  # Add commentary information
  cat(paste0(Sys.time(), ' | Commentary ...'))
  if (matches %>% nrow %>% `>`(0)) {
    KEYS %>% footballstats::acommentary_info(
      matchIDs = matches$zzz.matchID,
      localteam = matches$home.id,
      visitorteam = matches$away.id
    )
  }
  cat(' complete \n')

  # Add event information
  cat(paste0(Sys.time(), ' | Events ...'))
  if (matches %>% nrow %>% `>`(0)) {
    KEYS %>% footballstats::aevent_info(
      matchIDs = matches$zzz.matchID,
      matchEvents = matches$zzz.events
    )
  }
  cat(' complete \n')

  # Add team information
  teamListLength <- 'analyseTeams' %>% KEYS$RED$LLEN()
  plBef <- 'analysePlayers' %>% KEYS$RED$LLEN()

  cat(paste0(Sys.time(), ' | Teams ... \n'))
  # Add the team information
  if (teamListLength > 0) {
    KEYS %>% footballstats::ateam_info(
      teamListLength = teamListLength
    )
  }
  cat(' complete. \n\n')
  plAft <- 'analysePlayers' %>% KEYS$RED$LLEN()

  # Count the number of GET requests made. 2 for competition standing and match information
  uniqueRequests <- 2
  totalRequests <- uniqueRequests + teamListLength
  cat(paste0(Sys.time(), ' . ----------------{-S-U-M-M-A-R-Y-}------------------ \n'))
  cat(paste0(Sys.time(), ' | Analysed ', totalRequests, ' unique GET requests. \n'))
  cat(paste0(Sys.time(), ' | Analysed ', matches$zzz.events %>% length, ' matches/events. \n'))
  cat(paste0(Sys.time(), ' | Analysed ', teamListLength, ' teams. \n'))
  cat(paste0(Sys.time(), ' | Players to be analysed : ', plBef, ' -> ', plAft, '. \n'))
  cat(paste0(Sys.time(), ' ` -------------------------------------------------- \n\n'))
} # nocov end
