FROM eclipse-temurin:21-jre-jammy

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl tzdata \
    && ln -snf /usr/share/zoneinfo/Asia/Seoul /etc/localtime \
    && echo "Asia/Seoul" > /etc/timezone \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
VOLUME /tmp
EXPOSE 8080

# ★ 절대경로 ADD 금지 / 파일명 하드코딩 금지
COPY build/libs/*.jar /app/app.jar

# prod 고정하지 말고 환경변수로 제어
ENV JAVA_OPTS="-Xms1G -Xmx1G -XX:MaxMetaspaceSize=256m -XX:+UseG1GC -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/usr/spring-data/logs/heapdump.hprof"
ENTRYPOINT ["sh","-c","java $JAVA_OPTS -Dspring.config.additional-location=optional:file:/usr/spring-data/env/ -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE:-dev} -jar /app/app.jar"]