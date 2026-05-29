#Builder stage
FROM node:20.11.0-alpine AS builder
WORKDIR /app

COPY package*.json ./
#Faster in production dockerfiles
RUN npm ci

#Keep at buttom to avoid to take advantage of cache
COPY . .
RUN npm run build

#Runner stage
FROM nginx:1.25-alpine AS runner

#Take the build and use it on the right path
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

#This image dont have curl thats why using wget
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -q -O- http://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]