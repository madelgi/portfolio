FROM node:alpine3.18

RUN apk add --no-cache python3 make g++ autoconf automake libtool nasm build-base
RUN apk add --no-cache vips-dev fftw-dev
RUN apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/community --repository http://dl-3.alpinelinux.org/alpine/edge/main
RUN rm -fR /var/cache/apk/*

RUN npm install -g gatsby-cli

WORKDIR /app
COPY ./package.json .
RUN yarn install && yarn cache clean
COPY . .

EXPOSE 8000

ARG BUILD_ENV
RUN if [ "${BUILD_ENV}" == "production" ]; then gatsby build ; fi
RUN ["chmod", "+x", "./bin/run.sh"]
CMD ["./bin/run.sh"]
