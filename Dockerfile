# Dockerfile for NestJS

# --- Build Stage ---
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
# Use 'npm ci' for CI environments to ensure reproducible builds
RUN npm ci

# Copy the rest of the application source code
COPY . .

# Build the application
RUN npm run build

# --- Production Stage ---
FROM node:18-alpine

WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install only production dependencies
RUN npm ci --omit=dev

# Copy the built application from the builder stage
COPY --from=builder /app/dist ./dist

# Expose the port the app runs on
EXPOSE 3000

# Start the application
CMD ["node", "dist/main"]