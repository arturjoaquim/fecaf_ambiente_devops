const express = require('express');
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('./swagger.json');
const packageJson = require('./package.json');

const app = express();
const port = 3000;

// Atualiza a versão do Swagger dinamicamente usando a do package.json
swaggerDocument.info.version = packageJson.version;

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

app.get('/', (req, res) => {
  res.json({ 
    message: 'Hello World',
    version: packageJson.version 
  });
});

app.listen(port, () => {
  console.log(`API rodando em http://localhost:${port}`);
  console.log(`Documentação Swagger disponível em http://localhost:${port}/api-docs`);
});