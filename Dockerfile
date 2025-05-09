FROM node:lts-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build

FROM node:lts-alpine
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/src/metrics.js /app/src/metrics.js
COPY --from=build /app/src/metrics-server.js /app/src/metrics-server.js
COPY package.json package-lock.json ./
RUN npm install --production
RUN npm install -g serve

EXPOSE 5173 9113

# Create startup script (with explicit command and proper line endings)
RUN echo '#!/bin/sh' > /app/start.sh && \
    echo 'npm run metrics & serve -s dist -l 5173' >> /app/start.sh && \
    chmod +x /app/start.sh

# Verify the script exists and is executable
RUN ls -la /app/start.sh && cat /app/start.sh

CMD ["/bin/sh", "/app/start.sh"]
