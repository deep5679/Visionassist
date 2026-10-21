# VisionAssist static site served by a non-root nginx image
FROM nginxinc/nginx-unprivileged:1.27-alpine

# Apply the latest OS security patches (fixes Trivy findings), then drop back to the non-root user
USER root
RUN apk update && apk upgrade --no-cache
USER 101

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html style.css app.js utils.js /usr/share/nginx/html/

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost:8080/ >/dev/null || exit 1
