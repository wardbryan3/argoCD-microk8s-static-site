# Use the official lightweight Nginx image
FROM nginx:alpine

# Copy my static HTML file to the directory that Nginx severs files from
COPY index.html /usr/share/nginx/html/

# Inform Docker that the container listens on port 80
EXPOSE 80

# The default command to run Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
