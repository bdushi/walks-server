# syntax=docker/dockerfile:1

FROM eclipse-temurin:22-jdk AS build
WORKDIR /app

COPY gradlew settings.gradle.kts build.gradle.kts ./
COPY gradle ./gradle
COPY src ./src

RUN chmod +x ./gradlew && ./gradlew --no-daemon bootJar

FROM eclipse-temurin:22-jre
WORKDIR /app

COPY --from=build /app/build/libs/*.jar /app/
RUN set -eux; \
  ls -1 /app/*.jar; \
  JAR="$(ls -1 /app/*.jar | grep -v -- '-plain\\.jar$' | head -n 1)"; \
  mv "$JAR" /app/app.jar; \
  rm -f /app/*-plain.jar || true

EXPOSE 8080
ENV JAVA_OPTS=""

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
