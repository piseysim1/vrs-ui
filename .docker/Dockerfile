FROM nginx:1.17.1-alpine

RUN rm /etc/nginx/conf.d/default.conf

# Copy build output directly into a /vrms folder inside html root
COPY ./build/web /usr/share/nginx/html/vrms
COPY ./.docker/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]