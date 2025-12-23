FROM node:20

WORKDIR /strapi

RUN apt-get update && apt-get install -y python3 make g++ bash

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

EXPOSE 1337

CMD ["npm", "start"]
