set -e

TAG_UNIQUE_ID=`git ls-tree HEAD | sha256sum | cut -c-16`

docker build --pull -f Dockerfile.rpi.buster -t cgutman/moonlight-packaging:rpi-buster_$TAG_UNIQUE_ID .
docker build --pull -f Dockerfile.rpi.buster64 -t cgutman/moonlight-packaging:rpi-buster64_$TAG_UNIQUE_ID .
docker build --pull -f Dockerfile.amd64.buster -t cgutman/moonlight-packaging:amd64-buster_$TAG_UNIQUE_ID .
docker build --pull -f Dockerfile.l4t.bionic -t cgutman/moonlight-packaging:l4t-bionic_$TAG_UNIQUE_ID .

docker push cgutman/moonlight-packaging:rpi-buster_$TAG_UNIQUE_ID
docker push cgutman/moonlight-packaging:rpi-buster64_$TAG_UNIQUE_ID
docker push cgutman/moonlight-packaging:amd64-buster_$TAG_UNIQUE_ID
docker push cgutman/moonlight-packaging:l4t-bionic_$TAG_UNIQUE_ID
