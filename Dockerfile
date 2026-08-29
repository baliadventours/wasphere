# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

RUN corepack enable

# 1. Copy workspace config & SEMUA package.json dulu
COPY pnpm-workspace.yaml ./
COPY package.json ./
COPY packages/dashboard-api/package.json ./packages/dashboard-api/
COPY packages/dashboard-ui/package.json ./packages/dashboard-ui/
COPY packages/wa-server/package.json ./packages/wa-server/

# 2. Install SEMUA dependencies (termasuk devDependencies untuk build)
RUN pnpm install --frozen-lockfile

# 3. Baru copy source code
COPY . .

# 4. Build
RUN pnpm run build

# Stage 2: Production Runtime
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

RUN corepack enable

# Copy workspace config & package.json
COPY pnpm-workspace.yaml ./
COPY package.json ./
COPY packages/dashboard-api/package.json ./packages/dashboard-api/
COPY packages/dashboard-ui/package.json ./packages/dashboard-ui/
COPY packages/wa-server/package.json ./packages/wa-server/

# Install prod dependencies saja
RUN pnpm install --prod --frozen-lockfile

# Copy build output
COPY --from=builder /app/dist ./dist

EXPOSE 3000

CMD ["node", "dist/main.js"]
