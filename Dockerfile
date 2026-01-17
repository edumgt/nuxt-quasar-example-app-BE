FROM eclipse-temurin:21-jre-jammy
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl tzdata \
    && ln -snf /usr/share/zoneinfo/Asia/Bangkok /etc/localtime \
    && echo "Asia/Bangkok" > /etc/timezone \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

VOLUME /tmp
EXPOSE 8080
ADD /build/libs/api-service-1.0.0.jar app.jar
#ENTRYPOINT ["java","-jar","app.jar", "--spring.config.location=/usr/gd5data/env/application.yml"]
ENTRYPOINT ["java","-Xms1G","-Xmx1G","-XX:MaxMetaspaceSize=256m","-XX:+UseG1GC","-XX:+HeapDumpOnOutOfMemoryError","-XX:HeapDumpPath=/usr/spring-data/logs/heapdump.hprof ","-Dspring.config.additional-location=/usr/spring-data/env/","-Dspring.profiles.active=prod","-jar","app.jar"]
