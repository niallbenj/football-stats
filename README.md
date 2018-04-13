## Code status
[![Build Status](https://travis-ci.org/niallbenj/footballstats.svg?branch=master)](https://travis-ci.org/niallbenj/footballstats)
[![codecov](https://codecov.io/gh/niallbenj/footballstats/branch/master/graph/badge.svg)](https://codecov.io/gh/niallbenj/footballstats)

## Installing and running this package
```
# Run this as a script

# Install football stats from github
cat(' ## Installing footballstats \n ## ')

library(devtools)

devtools::install_github(
  repo = "niallbenj/footballstats"
)

library(footballstats)

cat(' ## Install Complete. \n\n')

# Set up log directory
footballstats::create_log_dir()
``` 

#### Deployment
  - Download and install [redis](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-redis) then from the command line start it by typing
```
cd redis-stable/utils
sudo ./install_server.sh
```
To start and stop the redis server type `sudo service redis_6379 start / stop`
  - Edit the `/usr/lib/R/etc/Rprofile.site` file and include the following 3 tokens
```
Sys.setenv(FS_HOST = "___")
Sys.setenv(FS_APIKEY = "Authorization=___")
Sys.setenv(FS_SLACK = "___")
Sys.setenv(FS_DEPLOYLOC = "___")
```
where the last token is the root path of where the above script is run from, e.g. `/root/`.
  - Set up a cron job by typing `crontab -e` with the following...
```
# Collect football information - such as match / team / commentary information
50 23 * * 0 Rscript -e 'library(footballstats); footballstats::analyse_data(deployed = TRUE)'

# Make predictions on upcoing fixtures
0 22 * * 0 Rscript -e 'library(footballstats); footballstats::predict_fixtures(deployed = TRUE)'

# After information has been gathered - update player status etc (COSTLY operation!)
0 22 * * 1 Rscript -e 'library(footballstats); footballstats::analyse_players(deployed = TRUE)'

# Generate report
# ...
```

## Tagging a release
  - Update `DESCRIPTION` file to required version (must be > than most recent `GIT` version).
  - Run `Rscript tag.R {v#}` inside root directory `/footballstats/`.
  - Update Github with the newest tag and binary that is produced from step 2.


## Scripts
There are a number of useful scripts for testing and building models. Make sure that `redis` is running on port `6379`.

  - In order to run the tests on a local machine, run from the root directory;
    - `Rscript demo/run_tests.R`
  - To rebuild one of the data models with updated information in redis, run from the root directory
    - `Rscript demo/create_nn.R`

## Accuracy
Below will be information on the accuracy so far that the app is achieving. To add more results, run through the data sets and append to the `data/accuracyFrame` data set in a similar fashion and from the root directory create the plot by running `Rscript demo/create_acc_plot.R` and push the new image to the repo.
![Accuracy Data Frame](https://raw.githubusercontent.com/niallbenj/footballstats/master/plots/accuracy.png)

## Weekly Accuracy
This is the accuracy across all competitions on a week by week basis, a more realistic idea of how well the app performs weekly.
![Accuracy Data Frame](https://raw.githubusercontent.com/niallbenj/footballstats/master/plots/weekly-accuracy.png)
