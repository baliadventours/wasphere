# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

RUN corepack enable
RUN apk add --no-cache git

COPY pnpm-workspace.yaml ./
COPY package.json ./
COPY packages/dashboard-api/package.json ./packages/dashboard-api/
COPY packages/dashboard-ui/package.json ./packages/dashboard-ui/
COPY packages/wa-server/package.json ./packages/wa-server/

RUN pnpm install --no-frozen-lockfile --config.ignore-scripts=true

COPY . .
RUN cd packages/dashboard-api && npx prisma generate
RUN pnpm run build

# Stage 2: Production Runtime
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

RUN corepack enable
RUN apk add --no-cache git

COPY pnpm-workspace.yaml ./
COPY package.json ./
COPY packages/dashboard-api/package.json ./packages/dashboard-api/
COPY packages/dashboard-ui/package.json ./packages/dashboard-ui/
COPY packages/wa-server/package.json ./packages/wa-server/
COPY --from=builder /app/pnpm-lock.yaml ./

RUN pnpm install --prod --no-frozen-lockfile --config.ignore-scripts=true

COPY --from=builder /app/packages/dashboard-api/dist ./packages/dashboard-api/dist
COPY --from=builder /app/packages/dashboard-api/prisma ./packages/dashboard-api/prisma
COPY --from=builder /app/packages/dashboard-api/node_modules ./packages/dashboard-api/node_modules

EXPOSE 3000

CMD ["node", "packages/dashboard-api/dist/main.js"]
