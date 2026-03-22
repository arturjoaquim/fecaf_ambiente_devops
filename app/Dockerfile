FROM node:18
LABEL authors="artur"

WORKDIR /app

COPY app/package*.json ./

RUN npm install

COPY app .

EXPOSE 3000

ENTRYPOINT ["npm", "start"]
