FROM node:18-alpine AS base
WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci --omit=dev

COPY . .

USER node
EXPOSE 6789
ENV NODE_ENV=production
CMD ["npm", "start"]