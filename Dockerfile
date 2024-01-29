# Build container
ARG GOVERSION=1.21.6
ARG ALPINEVERSION=3.19

FROM --platform=${BUILDPLATFORM} \
    golang:$GOVERSION-alpine${ALPINEVERSION} AS build

WORKDIR /src
RUN apk --no-cache add git build-base bash

ENV GO111MODULE=on \
    CGO_ENABLED=0

ARG VERSION=2024.1.4
RUN git clone https://github.com/cloudflare/cloudflared --depth=1 --branch ${VERSION} .
RUN bash -x .teamcity/install-cloudflare-go.sh

# From this point on, step(s) are duplicated per-architecture
ARG TARGETOS
ARG TARGETARCH
RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} make cloudflared

# Runtime container
FROM scratch
WORKDIR /

COPY --from=build /src/cloudflared .
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

ENV TUNNEL_ORIGIN_CERT=/etc/cloudflared/cert.pem
ENV NO_AUTOUPDATE=true
ENTRYPOINT ["/cloudflared", "--no-autoupdate"]
CMD ["version"]
