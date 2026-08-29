# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Salin package file terlebih dahulu untuk caching layer
COPY package*.json ./
RUN npm install

# Salin seluruh source code dan build aplikasi
COPY . .
RUN npm run build

# Stage 2: Production Runtime
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

# Salin package file dan install hanya production dependencies
COPY package*.json ./
RUN npm install --only=production

# Salin hasil build dari stage 1
COPY --from=builder /app/dist ./dist

# Port aplikasi (sesuaikan jika app Anda memakai port selain 3000)
EXPOSE 3000

# Jalankan aplikasi
CMD ["node", "dist/main.js"]
