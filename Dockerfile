# ---- build stage -------------------------------------------------------
    FROM --platform=$BUILDPLATFORM node:18-alpine AS builder

    WORKDIR /app
    
    # copy dependency manifests first to leverage Docker layer-cache
    COPY package*.json ./
    
    # install only production dependencies
    RUN npm ci --omit=dev
    
    # copy source
    COPY . .
    
    # ---- runtime stage -----------------------------------------------------
    FROM node:18-alpine
    
    WORKDIR /app
    
    # copy the app from the builder image
    COPY --from=builder /app /app
    
    # runtime env vars
    ENV NODE_ENV=production \
        PORT=3000
    
    EXPOSE 3000
    
    CMD ["node", "index.js"]
    