# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Enable corepack untuk pnpm
RUN corepack enable

# Copy pnpm-workspace.yaml TERLEBIH DAHULU
# Agar pnpm tahu ini monorepo sebelum install
COPY pnpm-workspace.yaml ./

# Copy semua package.json (root + sub-packages)
COPY package.json pnpm-lock.yaml ./
COPY packages/dashboard-api/package.json ./packages/dashboard-api/
COPY packages/dashboard-ui/package.json ./packages/dashboard-ui/
COPY packages/wa-server/package.json ./packages/wa-server/

# Install SEMUA dependencies (termasuk devDependencies untuk build)
RUN pnpm install --frozen-lockfile

# Copy semua source code
COPY . .

# Build semua packages
RUN pnpm run build

# Stage 2: Production Runtime
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

RUN corepack enable

# Copy pnpm-workspace.yaml
COPY pnpm-workspace.yaml ./

# Copy package files
COPY package.json pnpm-lock.yaml ./
COPY packages/dashboard-api/package.json ./packages/dashboard-api/
COPY packages/dashboard-ui/package.json ./packages/dashboard-ui/
COPY packages/wa-server/package.json ./packages/wa-server/

# Install production dependencies only
RUN pnpm install --prod --frozen-lockfile

# Copy build output dari semua packages
COPY --from=builder /app/packages/dashboard-api/dist ./packages/dashboard-api/dist
COPY --from=builder /app/packages/dashboard-ui/.next ./packages/dashboard-ui/.next
COPY --from=builder /app/packages/dashboard-ui/public ./packages/dashboard-ui/public
COPY --from=builder /app/packages/wa-server/dist ./packages/wa-server/dist

EXPOSE 3000

CMD ["node", "packages/dashboard-api/dist/main.js"]
