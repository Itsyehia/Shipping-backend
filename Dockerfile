# Stage 1: Build the Go application
FROM golang:1.23-alpine AS builder

# Install necessary packages
RUN apk update && apk add --no-cache git

# Set working directory inside the container
WORKDIR /app

# Copy go.mod and go.sum files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the rest of the application source code
COPY . .

# Build the Go application
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

# Stage 2: Create the final lightweight image
FROM alpine:latest

# Install necessary packages
RUN apk --no-cache add ca-certificates

# Set working directory
WORKDIR /app

# Copy the built binary from the builder stage
COPY --from=builder /app/main .

# Grant execution permissions to the binary for all users
RUN chmod a+x /app/main

# Ensure the /app directory is accessible
RUN chmod 755 /app

# (Optional) Remove non-root user setup to simplify permissions
# If you prefer running as a non-root user, ensure all necessary permissions are set
 RUN addgroup -S appgroup && adduser -S appuser -G appgroup
 RUN chown -R appuser:appgroup /app
 USER appuser

# Expose the port the app runs on
EXPOSE 4300

# Add environment variables for MySQL connection
ENV DB_HOST=mysql-service
ENV DB_PORT=3306
ENV MYSQL_USER=admin
ENV MYSQL_PASSWORD=adminpass
ENV MYSQL_DATABASE=tools

# Command to run the executable using absolute path
CMD ["/app/main"]
