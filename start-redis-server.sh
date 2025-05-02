#!/usr/bin/dumb-init /bin/sh

################################
# ---------- ENV VARS ----------
################################
# ENABLE_IPV6
# ENABLE_REDISINSIGHT
# REDIS_PASSWORD
# REDISEARCH_ARGS
# REDISJSON_ARGS
# REDISTIMESERIES_ARGS
# REDISBLOOM_ARGS
# REDISGEARS_ARGS

set -e

BASEDIR=/opt/redis-stack
cd ${BASEDIR}

CMD=${BASEDIR}/bin/redis-server

# SET CONFFILE
if [ -f /redis-stack.conf ]; then
    CONFFILE=/redis-stack.conf
fi

# SET REDIS_DATA_DIR
if [ -z "${REDIS_DATA_DIR}" ]; then
    REDIS_DATA_DIR=/data
fi

# SET REDIS_INSIGHT BIND HOST PORT
if [ "${ENABLE_REDISINSIGHT}" = "true" ] && [ "${ENABLE_IPV6}" = "true" ]; then
    echo "\nRI_APP_HOST=::\n" >> ${BASEDIR}/share/redisinsight/.env
    echo "\nRI_LOG_LEVEL=debug\n" >> ${BASEDIR}/share/redisinsight/.env
fi

# START
if [ "${ENABLE_REDISINSIGHT}" = "true" ] && [ -f ${BASEDIR}/nodejs/bin/node ]; then
  # when running in redis-stack (as opposed to redis-stack-server)
  echo "Starting RedisInsight..."
  # https://redis.io/docs/latest/operate/redisinsight/configuration/
  ${BASEDIR}/nodejs/bin/node -r ${BASEDIR}/share/redisinsight/api/node_modules/dotenv/config ${BASEDIR}/share/redisinsight/api/dist/src/main.js dotenv_config_path=${BASEDIR}/share/redisinsight/.env &
fi

if [ -z "${REDISEARCH_ARGS}" ]; then
    REDISEARCH_ARGS="MAXSEARCHRESULTS 10000 MAXAGGREGATERESULTS 10000"
fi

# Memory settings
sysctl vm.overcommit_memory=1 || true
sysctl net.core.somaxconn=1024 || true

# Set maxmemory-policy to 'allkeys-lru' for caching servers that should always evict old keys
: ${MAXMEMORY_POLICY:="volatile-lru"}
: ${APPENDONLY:="no"}
: ${FLY_VM_MEMORY_MB:=512}
if [ "${NOSAVE}" = "" ] ; then
  : ${SAVE:="3600 1 300 100 60 10000"}
fi

# Set maxmemory to 10% of available memory
MAXMEMORY=$(($FLY_VM_MEMORY_MB*90/100))


# REDIS ARGS - Password
FLY_REDIS_ARGS=${REDIS_ARGS:-""}
if [ ! -z "${REDIS_PASSWORD}" ]; then
    FLY_REDIS_ARGS="${FLY_REDIS_ARGS} --requirepass ${REDIS_PASSWORD}"
fi
echo FLY_REDIS_ARGS: ${FLY_REDIS_ARGS}

# https://redis.io/docs/latest/operate/oss_and_stack/management/config-file/
${CMD} \
  --dir ${REDIS_DATA_DIR} \
  --protected-mode no \
  --daemonize no \
  --maxmemory "${MAXMEMORY}mb" \
  --maxmemory-policy $MAXMEMORY_POLICY \
  --appendonly $APPENDONLY \
  --save "$SAVE" \
  --loadmodule /opt/redis-stack/lib/rediscompat.so \
  --loadmodule /opt/redis-stack/lib/redisearch.so ${REDISEARCH_ARGS} \
  --loadmodule /opt/redis-stack/lib/rejson.so ${REDISJSON_ARGS} \
  --loadmodule /opt/redis-stack/lib/redisgears.so v8-plugin-path /opt/redis-stack/lib/libredisgears_v8_plugin.so  ${REDISGEARS_ARGS} \
  ${FLY_REDIS_ARGS}
  # --loadmodule /opt/redis-stack/lib/redistimeseries.so ${REDISTIMESERIES_ARGS} \
  # --loadmodule /opt/redis-stack/lib/redisbloom.so ${REDISBLOOM_ARGS} \
