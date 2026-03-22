# Stage 1: Builder
FROM node:20 AS builder

WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install

# Copy configuration and source files
COPY tsconfig.json webpack.config.js ./
COPY src/ ./src/
COPY public/ ./public/

# Build arg for API URL
ARG API_BASE_URL=http://localhost:8000

# Build the application (webpack will inject API_BASE_URL via DefinePlugin)
RUN API_BASE_URL=${API_BASE_URL} npm run build

# Stage 2: Runtime with nginx
FROM nginx:alpine

# Copy built assets from builder stage
COPY --from=builder /app/dist/bundle.js /usr/share/nginx/html/bundle.js
COPY --from=builder /app/public/index.html /usr/share/nginx/html/index.html

# Create nginx configuration
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
