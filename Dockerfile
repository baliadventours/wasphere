# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Enable corepack untuk gunakan pnpm versi yang benar (9.0.0)
RUN corepack enable

COPY package*.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .
RUN pnpm run build

# Stage 2: Production Runtime
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

RUN corepack enable

COPY package*.json pnpm-lock.yaml ./
RUN pnpm install --prod --frozen-lockfile

COPY --from=builder /app/dist ./dist

EXPOSE 3000

CMD ["node", "dist/main.js"]
