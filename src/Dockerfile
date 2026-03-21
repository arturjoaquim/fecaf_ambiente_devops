FROM node:18
LABEL authors="artur"

WORKDIR /app

COPY package*.json ./

RUN npm install

# Copia o restante dos arquivos do projeto (index.js, swagger.json, etc)
COPY . .

EXPOSE 3000

ENTRYPOINT ["npm", "start"]
