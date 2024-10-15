# Use the official Node.js 14 image as the base image
FROM node:alpine

# Set the working directory
WORKDIR /app

# Copy package.json and yarn.lock files
COPY package.json yarn.lock ./

# Install dependencies
RUN yarn install

# Copy the rest of the application code
COPY . .

# Build the application (if necessary)
# RUN yarn 

# Expose the application port
EXPOSE 3000 

# Migrate the application
ENTRYPOINT [ "yarn", "migration:start" ]