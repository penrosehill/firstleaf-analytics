FROM r-base
RUN apt-get update && apt-get install -y software-properties-common gnupg openjdk-11-jdk openjdk-11-jre
RUN ln -s /usr/lib/jvm/java-11-openjdk-amd64 /usr/lib/jvm/default-java

RUN ["install2.r", "BTYDplus", "rJava", "RJDBC", "plyr"]

COPY . /usr/local/src/scripts
WORKDIR /usr/local/src/scripts
CMD ["Rscript", "pareto_ggg_production_single_dataset_final.R"]
