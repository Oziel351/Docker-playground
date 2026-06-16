#Builder stage
FROM node:20-alpine AS builder
WORKDIR /app

#Install pnpm
RUN npm install -g pnpm

#Layer caching 
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# Copia el código y buildea
COPY . .
RUN pnpm run build

#Runtime stage
FROM nginx:alpine AS runner

# Copy build
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q -O- http://localhost:80 || exit 1

CMD ["nginx", "-g", "daemon off;"]