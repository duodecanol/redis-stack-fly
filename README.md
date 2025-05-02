The official repository for Running Redis Stack on Fly.io. Find the accompanying Docker image at [flyio/redis](https://hub.docker.com/repository/docker/flyio/redis).

## Usage

This installation requires setting a password on Redis. To do that, run `fly secrets set REDIS_PASSWORD=mypassword` before deploying. Keep
track of this password - it won't be visible again after deployment!

If you need no customizations, you can deploy using the official Docker image. See `fly.toml` in this repository for an example to get started with.
## Runtime requirements

By default, this Redis installation will only accept connections on the private IPv6 network, on the standard port 6379.

If you want to access it from the public internet, add a `[[services]]` section to your `fly.toml`. An example is included in this repo for accessing Redis on port 10000.


We recommend adding persistent storage for Redis data. If you skip this step, data will be lost across deploys or restarts. For Fly apps, the volume needs to be in the same region as the app instances. For example:

```cmd
flyctl volumes create redis_server --region ord
```
```out
      Name: redis_server
    Region: ord
   Size GB: 10
Created at: 02 Nov 20 19:55 UTC
```

To connect this volume to the app, `fly.toml` includes a `[mounts]` entry.

```
[mounts]
source      = "redis_server"
destination = "/data"
```

When the app starts, that volume will be mounted on /data.

## Redis Stack 기능 (Korean)

이 저장소는 이제 표준 Redis 대신 Redis Stack을 사용하도록 업데이트되었습니다. 주요 변경 사항은 다음과 같습니다:

*   **Dockerfile:** 기본 이미지가 `redis:alpine`에서 `redis/redis-stack`으로 변경되었습니다. 이를 통해 Redisearch, ReJSON, RedisBloom, RedisGraph, RedisTimeSeries와 같은 추가 모듈을 사용할 수 있습니다. `CMD` 대신 `ENTRYPOINT`를 사용하여 컨테이너 시작 스크립트를 실행합니다.
*   **fly.toml:**
    *   앱 이름 예시가 `redis-stack`으로 변경되었습니다.
    *   특정 Redis Stack 버전을 빌드 인수로 지정할 수 있습니다 (예: `REDIS_VERSION = "7.2.0-v15"`).
    *   VM 설정 (메모리, CPU) 예시가 추가되었습니다.
    *   주석 처리된 `[[services]]` 섹션을 활성화하면 외부 접근이 가능합니다. TCP 포트 10000을 통한 외부 접근 예시를 보여줍니다.
*   **start-redis-server.sh:**
    *   Redis Stack 모듈을 로드하는 로직이 추가되었습니다.
    *   `ENABLE_REDISINSIGHT=true` 환경 변수를 설정하여 RedisInsight 웹 UI를 활성화할 수 있습니다. (기본적으로 비활성화)
    *   `ENABLE_IPV6=true` 환경 변수를 설정하여 RedisInsight 의 ipv6 접근을 활성화할 수 있습니다. (기본적으로 비활성화)
    *   다양한 Redis Stack 모듈 (`REDISEARCH_ARGS`, `REDISJSON_ARGS` 등)에 대한 설정을 환경 변수로 전달할 수 있습니다.
    *   기본 메모리 정책 (`MAXMEMORY_POLICY`), `APPENDONLY` 설정 등 기존 Redis 설정도 계속 지원합니다.

**환경 변수를 통한 설정:**

`start-redis-server.sh` 스크립트는 이제 다음과 같은 환경 변수를 통해 Redis Stack의 동작을 제어할 수 있습니다:

*   `ENABLE_REDISINSIGHT`: `true`로 설정하면 RedisInsight UI가 활성화됩니다. Fly 앱의 `:8001` 포트로 접근할 수 있습니다.
*   `REDIS_PASSWORD`: Redis 서버 접속 비밀번호를 설정합니다. (필수)
*   `REDISEARCH_ARGS`: Redisearch 모듈에 전달할 인수를 지정합니다.
*   `REDISJSON_ARGS`: ReJSON 모듈에 전달할 인수를 지정합니다.
*   `REDISTIMESERIES_ARGS`: RedisTimeSeries 모듈에 전달할 인수를 지정합니다.
*   `REDISBLOOM_ARGS`: RedisBloom 모듈에 전달할 인수를 지정합니다.
*   `REDISGEARS_ARGS`: RedisGears 모듈에 전달할 인수를 지정합니다.

이러한 환경 변수는 `fly secrets set VAR_NAME=value` 명령어를 사용하여 설정할 수 있습니다.

## FlyIO `_apps.internal` 통한 접근

해당 앱은 public 접근이 가능하지 않은 상태를 고려합니다.  

**fly wireguard 활성화**
*    `wg-quick up [[service]]` 명령어로 fly 조직의 VPN에 접속합니다.
*    `dig txt _apps.internal` 명령어로 앱의 hostname을 확인합니다.  `fly.toml`에 정의된 바와 같이 `redis-stack` 임을 확인합니다.

**redis 접속 테스트**
*    `uv` 사용
*    `uv tool install iredis -U` 명렁어로 `iredis` 툴을 설치합니다.
*    `iredis --url redis://default:${REDIS_PASSWORD}@redis-stack.internal:6379/1` 명렁어로 redis에 접속하여 명령어를 테스트합니다.

**RedisInsight 접속**
*    브라우저에서 domain name을 ipv6로 resolve하지 않으므로, ipv6 주소를 `nslookup` 명렁어로 확인합니다.
  *    `nslookup redis-stack.internal`
* 확인한 주소를 이용해 브라우저에 주소를 입력합니다.
  *   `http://[${REDIS_STACK_FLY_IPV6_ADDRESS}]:8001`


## Cutting a release

If you have write access to this repo, you can ship a prerelease or full release with:

```
scripts/bump_version.sh
```
or
```
scripts/bump_version.sh prerel
```
