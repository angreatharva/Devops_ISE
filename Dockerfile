FROM node:lts-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build

FROM node:lts-alpine
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY package.json package-lock.json ./
RUN npm install --production
RUN npm install -g serve

EXPOSE 5173
CMD ["serve", "-s", "dist", "-l", "5173"]
