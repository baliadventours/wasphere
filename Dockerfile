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

# ✅ Install DULU tanpa postinstall (karena source belum ada)
RUN pnpm install --no-frozen-lockfile --config.ignore-scripts=true

# ✅ Baru copy source code
COPY . .

# ✅ Jalankan prisma generate SETELAH source ada
RUN cd packages/dashboard-api && npx prisma generate

# ✅ Build
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

# ✅ Install prod DULU tanpa postinstall
RUN pnpm install --prod --no-frozen-lockfile --config.ignore-scripts=true

# ✅ Copy source & generate prisma
COPY --from=builder /app/packages ./packages
RUN cd packages/dashboard-api && npx prisma generate

EXPOSE 3000

CMD ["node", "dist/main.js"]
