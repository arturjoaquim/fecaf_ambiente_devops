FROM node:18
LABEL authors="artur"

WORKDIR /app

COPY src/package*.json ./

RUN npm install

COPY src .

EXPOSE 3000

ENTRYPOINT ["npm", "start"]
