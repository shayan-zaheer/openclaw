# FROM node:22-bookworm

# # Install Bun (required for build scripts)
# RUN curl -fsSL https://bun.sh/install | bash
# ENV PATH="/root/.bun/bin:${PATH}"

# RUN corepack enable

# WORKDIR /app

# ARG OPENCLAW_DOCKER_APT_PACKAGES=""
# RUN if [ -n "$OPENCLAW_DOCKER_APT_PACKAGES" ]; then \
#       apt-get update && \
#       DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $OPENCLAW_DOCKER_APT_PACKAGES && \
#       apt-get clean && \
#       rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
#     fi

# COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
# COPY ui/package.json ./ui/package.json
# COPY patches ./patches
# COPY scripts ./scripts

# RUN pnpm install --frozen-lockfile

# COPY . .
# RUN OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build
# # Force pnpm for UI build (Bun may fail on ARM/Synology architectures)
# ENV OPENCLAW_PREFER_PNPM=1
# RUN pnpm ui:build

# ENV NODE_ENV=production

# # Security hardening: Run as non-root user
# # The node:22-bookworm image includes a 'node' user (uid 1000)
# # This reduces the attack surface by preventing container escape via root privileges
# USER node

# CMD ["node", "dist/index.js"]

# -------------------------
# Base image
# -------------------------
FROM node:22-bookworm

# Install Bun for build scripts
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"
RUN corepack enable

WORKDIR /app

# Optional system deps
ARG OPENCLAW_DOCKER_APT_PACKAGES=""
RUN if [ -n "$OPENCLAW_DOCKER_APT_PACKAGES" ]; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $OPENCLAW_DOCKER_APT_PACKAGES && \
      apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
    fi

# Install dependencies
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts
RUN pnpm install --frozen-lockfile

# Copy code and build
COPY . .
RUN OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

# Ensure the CLI binary is exposed where the shell can find it
RUN ln -s /app/node_modules/.bin/openclaw /usr/local/bin/openclaw

ENV NODE_ENV=production
ENV PORT=8080
EXPOSE 8080

# Use gateway with --allow-unconfigured so it runs without config file
CMD ["sh", "-c", "openclaw gateway --port $PORT --allow-unconfigured"]
