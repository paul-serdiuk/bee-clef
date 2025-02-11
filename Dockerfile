FROM golang:1.15 as build

ARG TAG="v1.9.24"

RUN apt-get update && apt-get install -y \
    make \
    gcc \
    libc6-dev \
    git; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*;

RUN git clone https://github.com/ethereum/go-ethereum.git && cd /go/go-ethereum && \
    if [[ -n $TAG ]]; then git checkout $TAG; fi && env GO111MODULE=on go run build/ci.go install ./cmd/clef

FROM debian:buster-slim as runtime

RUN mkdir -p /app/data && chown nobody:nogroup /app/data

RUN apt-get update && apt-get install -y \
    curl \
    jq \
    ca-certificates; \
    apt-get clean;

COPY --from=build /go/go-ethereum/build/bin/clef /usr/local/bin/clef
COPY packaging/rules.js /app/config/rules.js
COPY packaging/4byte.json /app/config/4byte.json
COPY packaging/docker/entrypoint.sh /entrypoint.sh

EXPOSE 8550
USER nobody
WORKDIR /app
VOLUME /app/data

ENTRYPOINT ["/entrypoint.sh"]
