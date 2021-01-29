FROM r-base
RUN apt-get update && apt-get install -y software-properties-common gnupg openjdk-11-jdk openjdk-11-jre python python3-pip
RUN ln -s /usr/lib/jvm/java-11-openjdk-amd64 /usr/lib/jvm/default-java

RUN ["install2.r", "BTYDplus", "rJava", "RJDBC", "plyr"]

RUN pip install awscli

RUN mkdir -p /usr/local/src/scripts
WORKDIR /usr/local/src/scripts
