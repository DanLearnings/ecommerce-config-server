# Multi-stage Dockerfile for Config Server
# Stage 1: Build
FROM maven:3.9.9-eclipse-temurin-21-alpine AS build

# Set working directory
WORKDIR /app

# Copy pom.xml and download dependencies (cached layer)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application (skip tests for faster builds)
RUN mvn clean package -DskipTests

# Stage 2: Runtime
FROM eclipse-temurin:21-jre-alpine

# Set working directory
WORKDIR /app

# Install git (required for cloning config repository)
RUN apk add --no-cache git

# Create a non-root user for security
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copy the JAR from build stage
COPY --from=build /app/target/*.jar app.jar

# Expose Config Server port
EXPOSE 8888

# Set environment variables
ENV JAVA_OPTS="-Xmx512m -Xms256m"
ENV SPRING_CLOUD_CONFIG_SERVER_GIT_URI="https://github.com/DanLearnings/ecommerce-config-repo"
ENV SPRING_CLOUD_CONFIG_SERVER_GIT_DEFAULT_LABEL="main"
ENV EUREKA_CLIENT_SERVICEURL_DEFAULTZONE="http://service-registry:8761/eureka/"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8888/actuator/health || exit 1

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]