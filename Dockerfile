# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

RUN corepack enable

# ✅ Install git untuk dependency GitHub-based (libsignal-node)
RUN apk add --no-cache git

COPY pnpm-workspace.yaml ./
COPY package.json ./
COPY packages/dashboard-api/package.json ./packages/dashboard-api/
COPY packages/dashboard-ui/package.json ./packages/dashboard-ui/
COPY packages/wa-server/package.json ./packages/wa-server/

RUN pnpm install --no-frozen-lockfile
COPY . .
RUN pnpm run build

# Stage 2: Production Runtime
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

RUN corepack enable

# ✅ Install git juga di runner (untuk install dependency)
RUN apk add --no-cache git

COPY pnpm-workspace.yaml ./
COPY package.json ./
COPY packages/dashboard-api/package.json ./packages/dashboard-api/
COPY packages/dashboard-ui/package.json ./packages/dashboard-ui/
COPY packages/wa-server/package.json ./packages/wa-server/
COPY --from=builder /app/pnpm-lock.yaml ./

RUN pnpm install --prod --no-frozen-lockfile
COPY --from=builder /app/dist ./dist

EXPOSE 3000

CMD ["node", "dist/main.js"]
