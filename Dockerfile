ARG REDIS_VERSION=latest
FROM redis/redis-stack:${REDIS_VERSION}

COPY start-redis-server.sh /usr/bin/start-redis-server.sh

ENTRYPOINT ["/usr/bin/start-redis-server.sh"]
