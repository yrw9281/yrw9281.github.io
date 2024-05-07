# Use an official Ruby runtime as a parent image
FROM ruby:3.1
# Set the working directory in the container to /app
WORKDIR /app
# Add current directory contents into the container at /app
ADD . /app
# Install Jekyll and required plugins
RUN gem install jekyll jekyll-seo-tag jekyll-paginate jekyll-sitemap
# Make port 4000 available to the world outside this container
EXPOSE 4000
# Run Jekyll server when the container launches
CMD ["jekyll", "serve", "--host", "0.0.0.0"]
# DOCKER RUN with volume
#docker run -p 4000:4000 -v .:/app keepnote