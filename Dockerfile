# syntax=docker/dockerfile:1
FROM golang:1.20-alpine AS build

ARG TARGETOS
ARG TARGETARCH
ARG VERSION=dev

ENV GOPROXY=https://proxy.golang.org
ENV GO111MODULE=on
ENV CGO_ENABLED=0
ENV GOPATH=/go

WORKDIR /go/src/app

COPY go.mod go.sum ./
RUN go mod download && go mod verify

COPY . ./
RUN \
     GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
     go build \
          -trimpath \
          -ldflags="-s -w -X main.version=$VERSION -extldflags '-static'" \
          -o /mp3binder \
          cmd/tui/main.go

FROM scratch

ENV TINI_VERSION=v0.19.0
ENV TINI_SHA256=c5b0666b4cb676901f90dfcb37106783c5fe2077b04590973b885950611b30ee
ADD --chmod=755 \
     --checksum=sha256:$TINI_SHA256 \
     https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static /tini

COPY --from=build /mp3binder /

EXPOSE 9311

ENTRYPOINT [ "/tini", "--", "/mp3binder" ]
CMD [ "--help" ]
