# docker/prism.Dockerfile
FROM node:18-alpine

# Add tini for proper SIGTERM handling (graceful shutdown in ECS)
RUN apk add --no-cache tini

# Install Prism CLI
RUN npm i -g @stoplight/prism-cli

WORKDIR /app
COPY docker/openapi.yaml /app/openapi.yaml

# Non-root user for safety
RUN addgroup -S prism && adduser -S prism -G prism
USER prism

EXPOSE 4010

# Use tini as init to handle signals; run Prism in mock mode
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["prism","mock","/app/openapi.yaml","-p","4010","-h","0.0.0.0","--cors","--dynamic=false"]
