# Step 1: Set up the base Node.js image
FROM node:18 AS build-stage

# Step 2: Set the working directory
WORKDIR /app

# Step 3: Copy package.json and yarn.lock first for faster dependency caching
COPY package.json yarn.lock ./

# Step 4: Install project dependencies
RUN yarn install

# Step 5: Copy the rest of the application code
COPY . .

# Step 6: Run build command to compile the application
RUN yarn build

# Final Stage: Set up the production image
FROM node:18 AS production-stage

WORKDIR /app

# Copy only the necessary files from the build-stage
COPY --from=build-stage /app /app

# Expose the port your app will run on
EXPOSE 8000

# Run the app using the compiled code
CMD ["yarn", "start"]
