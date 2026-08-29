# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

RUN corepack enable
RUN apk add --no-cache git

# Copy workspace config & SEMUA package.json dulu
COPY pnpm-workspace.yaml ./
COPY package.json ./
COPY packages/dashboard-api/package.json ./packages/dashboard-api/
COPY packages/dashboard-ui/package.json ./packages/dashboard-ui/
COPY packages/wa-server/package.json ./packages/wa-server/

# Install dependencies tanpa postinstall (source belum ada)
RUN pnpm install --no-frozen-lockfile --config.ignore-scripts=true

# Copy semua source code
COPY . .

# Generate Prisma client (setelah source ada)
RUN cd packages/dashboard-api && npx prisma generate

# Build semua packages
RUN pnpm run build

# Stage 2: Production Runtime
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

RUN corepack enable
RUN apk add --no-cache git

# Copy workspace config & package.json lagi
COPY pnpm-workspace.yaml ./
COPY package.json ./
COPY packages/dashboard-api/package.json ./packages/dashboard-api/
COPY packages/dashboard-ui/package.json ./packages/dashboard-ui/
COPY packages/wa-server/package.json ./packages/wa-server/

# Copy lockfile dari builder
COPY --from=builder /app/pnpm-lock.yaml ./

# Install production dependencies
RUN pnpm install --prod --no-frozen-lockfile --config.ignore-scripts=true

# Copy build output & node_modules yang dibutuhkan
COPY --from=builder /app/packages/dashboard-api/dist ./packages/dashboard-api/dist
COPY --from=builder /app/packages/dashboard-api/prisma ./packages/dashboard-api/prisma
COPY --from=builder /app/packages/dashboard-api/node_modules ./packages/dashboard-api/node_modules

EXPOSE 3000

CMD ["node", "packages/dashboard-api/dist/main.js"]
