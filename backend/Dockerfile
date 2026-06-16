#Stage for builder
FROM node:20-alpine AS builder
WORKDIR /app

#Get pnpm
RUN npm install -g pnpm

# Dependencies for layer caching
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

#Runtime stage
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production

#This user exists on the official image
USER node

# node_modules from builder
COPY --from=builder --chown=node:node /app/node_modules ./node_modules

# We copy the source code at the end because the code constantly changes and that reconstructs everything in a cascade and we do not take advantage of the cache 
COPY --chown=node:node src/ ./src
COPY --chown=node:node package.json ./

#Docs
EXPOSE 4000


HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q -O- http://localhost:4000/api/health || exit 1

  
CMD ["node", "src/server.js"]