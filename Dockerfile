FROM alpine:3.19.1 as cloner

ARG HEAD_REF=camcast3/docker
WORKDIR /repository
RUN apk add --no-cache git
RUN git clone https://github.com/camcast3/packwiz.git .
RUN git reset --hard ${HEAD_REF}

FROM golang:1.21 as build

WORKDIR /workspace
COPY --from=cloner /repository/go.mod /repository/go.sum ./
RUN go mod download
COPY --from=cloner /repository/ ./
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o packwiz main.go

FROM alpine:3.19.1 as app

WORKDIR /workspace
RUN apk add --no-cache bash
COPY --chmod=755 --from=build /workspace/packwiz /usr/local/bin/
VOLUME ["/data"]
WORKDIR /data
EXPOSE 8080

ENTRYPOINT [ "/packwiz", "server", "--port", "8080"]