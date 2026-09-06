# Use official Node.js 20 lightweight Alpine image
FROM node:20-alpine AS builder

WORKDIR /app

# Copy dependency manifests
COPY package*.json tsconfig.json ./

# Install all dependencies (including devDependencies for build)
RUN npm ci

# Copy source code
COPY src/ ./src

# Build TypeScript to JavaScript
RUN npm run build

# Production image stage
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

# Copy built app and production package manifest
COPY package*.json ./
RUN npm ci --only=production

COPY --from=builder /app/dist ./dist

# Expose Cloud Run HTTP port requirement (healthcheck / container startup requirement)
EXPOSE 8080

CMD ["node", "dist/index.js"]
