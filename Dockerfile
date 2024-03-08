FROM node:7.8.0-alpine
WORKDIR /opt
ADD . /opt
RUN npm install
ENTRYPOINT npm run start