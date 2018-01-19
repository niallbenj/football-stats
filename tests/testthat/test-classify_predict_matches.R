context('test-classify_all.R')

competitionID <- 1204
seasonStarting <- 2017
rredis::redisConnect(
  host = 'localhost',
  port = 6379)
rredis::redisSelect(3)
rredis::redisFlushDB()

test_that('Classify all - end to end from adding data to classifying and predicting.', {

  matchData <- footballstats::amatch_info(
    competitionID = competitionID,
    dateFrom = NULL,
    dateTo = NULL,
    seasonStarting = seasonStarting,
    analysingToday = TRUE,
    KEYS = KEYS)

  footballstats::acommentary_info(
    competitionID = competitionID,
    matchIDs = matchData$id,
    localteam = matchData$localteam_id,
    visitorteam = matchData$visitorteam_id,
    KEYS = KEYS)

  # Create the predictions here
  KEYS$LOG_PRED <- TRUE
  footballstats::predict_matches(
    competitionID = competitionID,
    competitionName = 'test-competition',
    KEYS = KEYS)
  KEYS$LOG_PRED <- FALSE

  predictions <- 'c:1204:pred*' %>%
    rredis::redisKeys() %>%
    strsplit(split = '[:]') %>%
    purrr::map(4) %>%
    purrr::flatten_chr() %>%
    as.integer %>%
    sort

  expect_that( predictions %>% length, equals(11) )
  expect_that( predictions[1], equals(2212967) )
})