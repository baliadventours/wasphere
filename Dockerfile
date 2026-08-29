# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

RUN corepack enable

# ✅ Copy workspace config DULU
COPY pnpm-workspace.yaml ./

# ✅ Copy SEMUA package.json (root + sub-packages) SEBELUM install
COPY package.json ./
COPY packages/dashboard-api/package.json ./packages/dashboard-api/
COPY packages/dashboard-ui/package.json ./packages/dashboard-ui/
COPY packages/wa-server/package.json ./packages/wa-server/

# ✅ Install SEMUA dependencies (termasuk devDependencies untuk build)
RUN pnpm install --no-frozen-lockfile

# ✅ Baru copy source code
COPY . .

# ✅ Build
RUN pnpm run build

# Stage 2: Production Runtime
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

RUN corepack enable

# ✅ Copy workspace config
COPY pnpm-workspace.yaml ./

# ✅ Copy SEMUA package.json lagi
COPY package.json ./
COPY packages/dashboard-api/package.json ./packages/dashboard-api/
COPY packages/dashboard-ui/package.json ./packages/dashboard-ui/
COPY packages/wa-server/package.json ./packages/wa-server/

# ✅ Copy lockfile dari builder (penting!)
COPY --from=builder /app/pnpm-lock.yaml ./

# ✅ Install production dependencies
RUN pnpm install --prod --no-frozen-lockfile

# ✅ Copy build output
COPY --from=builder /app/dist ./dist

EXPOSE 3000

CMD ["node", "dist/main.js"]
