FROM r-base
RUN apt-get update && apt-get install -y software-properties-common gnupg libpq-dev file libcurl4 libcurl4-openssl-dev libssl-dev libxml2 libgit2-dev libxml2-dev

RUN ["install2.r", "devtools","BTYDplus", "rJava", "RJDBC", "plyr"]
RUN ["installGithub.r", "sicarul/redshiftTools", "r-dbi/RPostgres"]
RUN ["install2.r", "aws.s3", "-r", "https://cloud.R-project.org"]

RUN mkdir -p /usr/local/src/scripts
WORKDIR /usr/local/src/scripts
