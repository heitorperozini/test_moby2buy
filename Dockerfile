 FROM nginx
 
 RUN apt-get update && apt-get upgrade -y
 
 COPY ./nginx/index.html /usr/share/nginx/html
 
 EXPOSE 80
 
 CMD ["nginx", "-g", "daemon off;"]