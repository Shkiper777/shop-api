# Этап 1: сборка jar
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
# Кэш ~/.m2 сохраняется между попытками сборки: если сеть оборвётся, скачанное не пропадёт.
RUN --mount=type=cache,target=/root/.m2 \
    mvn -B -q package -DskipTests \
    -Daether.connector.http.retryHandler.count=5 \
    -Dmaven.wagon.http.retryHandler.count=5

# Этап 2: лёгкий образ для запуска
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/shop-api.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
