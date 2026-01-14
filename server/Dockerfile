FROM eclipse-temurin:25-jdk

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

WORKDIR /hytale

COPY Assets.zip /hytale/Assets.zip
COPY HytaleServer.jar /hytale/HytaleServer.jar
COPY HytaleServer.aot /hytale/HytaleServer.aot

EXPOSE 5520/udp

ENV JAVA_OPTS="-Xms2G -Xmx4G"
ENV AOT_OPTS="-XX:AOTCache=/hytale/data/HytaleServer.aot"

CMD java $JAVA_OPTS $AOT_OPTS -jar /hytale/HytaleServer.jar --assets /hytale/Assets.zip
