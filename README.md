# Config Server

## 🎯 Purpose

The Config Server provides **centralized external configuration** for all microservices in the ecosystem. It pulls configurations from a Git repository, allowing you to manage application settings separately from code and change configurations without rebuilding services.

## 🔌 Port

- **Default Port:** `8888`
- **Config API:** http://localhost:8888

## 🛠️ Tech Stack

- **Framework:** Spring Boot 3.5.7
- **Configuration Management:** Spring Cloud Config Server
- **Service Discovery:** Spring Cloud Netflix Eureka Client
- **Backend:** Git (GitHub)
- **Monitoring:** Spring Boot Actuator
- **Containerization:** Docker
- **Build Tool:** Maven

## 📦 Dependencies

**Required Services:**
1. **Service Registry** (Eureka) - Must be running on port 8761

**External Dependencies:**
- Git repository containing configurations (https://github.com/DanLearnings/ecommerce-config-repo)

## ⚙️ Configuration

### Key Configuration (`application.yml`):

```yaml
server:
  port: 8888

spring:
  application:
    name: config-server
  cloud:
    config:
      server:
        git:
          uri: https://github.com/DanLearnings/ecommerce-config-repo
          default-label: main
          clone-on-start: true

eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
```

### Configuration Repository Structure

The linked Git repository should have this structure:

```
ecommerce-config-repo/
├── application.yml           # Global configs for ALL services
├── inventory-service.yml     # Inventory Service specific configs
├── order-service.yml         # Order Service specific configs
└── api-gateway.yml           # API Gateway specific configs (if needed)
```

### Important Notes:

- `clone-on-start: true` - Clones the Git repo immediately at startup
- `default-label: main` - Uses the 'main' branch
- Configurations are cached locally after the first fetch
- The repository must be accessible (public or with SSH keys configured)

---

## 🚀 How to Run

### Prerequisites

- Java 21 or higher
- Maven 3.8+
- Service Registry running on port 8761
- Access to the configuration Git repository
- Docker (for containerized deployment)

---

## 🐳 Option 1: Running with Docker (Recommended)

### Quick Start

```bash
# Ensure Service Registry is running first
docker run -d \
  --name service-registry \
  --network ecommerce-network \
  -p 8761:8761 \
  ecommerce-service-registry:latest

# Run Config Server
docker run -d \
  --name config-server \
  --network ecommerce-network \
  -p 8888:8888 \
  -e EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://service-registry:8761/eureka/ \
  ecommerce-config-server:latest
```

### Building the Docker Image

```bash
# Clone the repository
git clone https://github.com/DanLearnings/ecommerce-config-server.git
cd ecommerce-config-server

# Build the Docker image
docker build -t ecommerce-config-server:latest .

# Run the container
docker run -d \
  --name config-server \
  --network ecommerce-network \
  -p 8888:8888 \
  ecommerce-config-server:latest
```

### Docker Environment Variables

```bash
# Run with custom configurations
docker run -d \
  --name config-server \
  --network ecommerce-network \
  -p 8888:8888 \
  -e JAVA_OPTS="-Xmx1g -Xms512m" \
  -e SPRING_CLOUD_CONFIG_SERVER_GIT_URI=https://github.com/YourOrg/your-config-repo \
  -e SPRING_CLOUD_CONFIG_SERVER_GIT_DEFAULT_LABEL=main \
  -e EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://service-registry:8761/eureka/ \
  ecommerce-config-server:latest
```

### Viewing Logs

```bash
# View logs
docker logs config-server

# Follow logs in real-time
docker logs -f config-server
```

### Stopping and Removing

```bash
# Stop the container
docker stop config-server

# Remove the container
docker rm config-server

# Stop and remove in one command
docker rm -f config-server
```

---

## 💻 Option 2: Running with Maven (Development)

### Running Locally

```bash
# Clone the repository
git clone https://github.com/DanLearnings/ecommerce-config-server.git
cd ecommerce-config-server

# Ensure Service Registry is running first
# Then run Config Server
mvn spring-boot:run

# Or build and run the JAR
mvn clean package
java -jar target/ecommerce-config-server-1.0.0.jar
```

---

## 🔍 Endpoints

### Get Configuration for a Service

**Pattern:** `http://localhost:8888/{application}/{profile}/{label}`

**Examples:**

```bash
# Get default profile for inventory-service
curl http://localhost:8888/inventory-service/default

# Get production profile for inventory-service
curl http://localhost:8888/inventory-service/production

# Get config from specific branch
curl http://localhost:8888/inventory-service/default/develop
```

**Response Format:**
```json
{
  "name": "inventory-service",
  "profiles": ["default"],
  "label": null,
  "version": "522f5daeba9a3d82fde993f9ccfa4bf49470166a",
  "state": "",
  "propertySources": [
    {
      "name": "https://github.com/DanLearnings/ecommerce-config-repo/inventory-service.yml",
      "source": {
        "server.port": 8081,
        "spring.datasource.url": "jdbc:h2:mem:inventorydb",
        ...
      }
    }
  ]
}
```

### Health Check

```bash
curl http://localhost:8888/actuator/health
```

**Expected Response:**
```json
{
  "status": "UP"
}
```

### Check if Registered with Eureka

Visit http://localhost:8761 and verify **CONFIG-SERVER** appears in the instances list.

---

## ✅ Health Check

Verify the service is working correctly:

```bash
# 1. Check service health
curl http://localhost:8888/actuator/health

# 2. Verify it can fetch configurations
curl http://localhost:8888/inventory-service/default

# 3. Check Eureka registration
curl http://localhost:8761/eureka/apps/CONFIG-SERVER
```

---

## 🔧 How Client Services Connect

### When running locally (Maven):
```yaml
spring:
  application:
    name: inventory-service
  config:
    import: "configserver:http://localhost:8888"
  cloud:
    config:
      fail-fast: true  # Fail if cannot connect to Config Server
```

### When running in Docker:
```yaml
spring:
  application:
    name: inventory-service
  config:
    import: "configserver:http://config-server:8888"  # Use container name
  cloud:
    config:
      fail-fast: true
```

---

## 🐛 Troubleshooting

### Config Server cannot clone Git repository

**Symptom:** Error on startup: "Could not clone or checkout repository"

**Solutions:**
1. **Verify Git URL** is correct in `application.yml`
2. **For Private Repos:** Configure SSH keys or personal access tokens
3. **Check Network:** Ensure the server can reach GitHub
4. **Branch Name:** Verify `default-label` matches your branch name

### Service returns empty propertySource

**Symptom:** GET request succeeds but returns empty `propertySources: []`

**Solutions:**
1. **Verify file names** in Git repo match service names
2. **Check file location** - Files should be in root or specified `search-paths`
3. **YAML syntax** - Ensure configuration files are valid YAML
4. **Refresh repo** - Restart Config Server to re-clone

### Client service cannot connect to Config Server

**Symptom:** Client service logs: "Could not locate PropertySource"

**Solutions:**
1. **Verify Config Server is running** on port 8888
2. **Check URL** in client's `spring.config.import`
3. **Network connectivity** - Ensure services can communicate
4. **Use `optional:`** prefix if you want to allow fallback: `optional:configserver:http://...`

### Config Server not registering with Eureka

**Symptom:** CONFIG-SERVER doesn't appear in Eureka dashboard

**Solutions:**
1. **Ensure Eureka is running** before starting Config Server
2. **Check `eureka.client.service-url.defaultZone`** in configuration
3. **Wait 30 seconds** for initial registration
4. **Check logs** for connection errors

### Docker: Git not found in container

**Symptom:** Error logs show "git: command not found"

**Solution:**
```bash
# This should already be included in the Dockerfile
# Verify the Dockerfile contains:
# RUN apk add --no-cache git

# If missing, rebuild the image with updated Dockerfile
```

### Docker: Cannot connect to Service Registry

**Symptom:** Config Server logs show Eureka connection errors

**Solution:**
```bash
# Verify both containers are in the same network
docker network inspect ecommerce-network

# Ensure Service Registry is running and healthy
docker ps | grep service-registry

# Test connectivity
docker exec config-server ping service-registry
```

### Docker: Configuration not updating

**Symptom:** Changes in Git repo don't reflect in Config Server

**Solution:**
```bash
# Git configurations are cached
# Restart the container to force re-clone
docker restart config-server

# Or use the refresh endpoint
curl -X POST http://localhost:8888/actuator/refresh
```

---

## 📚 Git Repository Best Practices

### File Naming Convention

- `application.yml` - Global configuration for ALL services
- `{service-name}.yml` - Service-specific configuration
- `{service-name}-{profile}.yml` - Profile-specific configuration

### Example Repository Structure

```
ecommerce-config-repo/
├── application.yml              # Global defaults
├── application-dev.yml          # Development environment
├── application-prod.yml         # Production environment
├── inventory-service.yml        # Inventory defaults
├── inventory-service-dev.yml    # Inventory dev overrides
└── inventory-service-prod.yml   # Inventory prod overrides
```

### Configuration Priority

1. Service-specific profile config (`inventory-service-prod.yml`)
2. Service-specific default config (`inventory-service.yml`)
3. Global profile config (`application-prod.yml`)
4. Global default config (`application.yml`)

---

## 🔄 Refreshing Configuration at Runtime

To refresh configuration without restarting services:

1. **Update configuration** in Git repository
2. **Commit and push** changes
3. **Trigger refresh** on client services:

```bash
curl -X POST http://localhost:8081/actuator/refresh
```

*Note: Requires `@RefreshScope` annotation on beans that should be refreshed*

---

## 🐳 Docker Image Details

### Multi-stage Build

The Dockerfile uses a multi-stage build:
- **Stage 1 (build):** Uses Maven image to compile the application
- **Stage 2 (runtime):** Uses lightweight JRE image with Git installed

### Important Docker Features

- **Git Installation:** `apk add --no-cache git` - Required to clone config repository
- **Non-root user:** Runs as `spring:spring` for security
- **Health check:** Built-in health check with 60s start period (allows time for Git clone)
- **Environment variables:** Customizable Git URI, branch, and Eureka location

### Health Check

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8888/actuator/health || exit 1
```

*Note: Longer start period (60s) allows time for Git repository cloning*

---

## 📚 Additional Resources

- [Spring Cloud Config Documentation](https://cloud.spring.io/spring-cloud-config/)
- [Spring Cloud Config Reference](https://docs.spring.io/spring-cloud-config/docs/current/reference/html/)
- [Configuration Repository](https://github.com/DanLearnings/ecommerce-config-repo)
- [Docker Documentation](https://docs.docker.com/)

## 🔗 Related Services

- [Service Registry](https://github.com/DanLearnings/ecommerce-service-registry) - Service discovery (required)
- [Config Repository](https://github.com/DanLearnings/ecommerce-config-repo) - Stores configurations (required)
- All microservices - Pull their configurations from this server

---

## 👨‍💻 Maintainer

**Danrley Brasil (Dan Learnings)**
- Personal GitHub: [@DanrleyBrasil](https://github.com/DanrleyBrasil)
- Organization: [DanLearnings](https://github.com/DanLearnings)

---

**Last Updated:** October 29, 2025
