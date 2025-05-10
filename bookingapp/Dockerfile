# Build stage
FROM maven:3.8.4-openjdk-8-slim AS build
WORKDIR /app
COPY . .
RUN mvn clean package -DskipTests

# Run stage
FROM openjdk:8-jre-slim
WORKDIR /app
COPY --from=build /app/target/concert-booking-app-1.0-SNAPSHOT.jar ./app.jar

# Set environment variables
ENV JAVA_OPTS="-Xmx512m -Xms256m"

# Expose the port the app runs on
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"] 