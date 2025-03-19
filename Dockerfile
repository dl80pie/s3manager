FROM harbor.pietschnet.com/redhat/ubi9:latest AS builder
USER root
RUN dnf upgrade -y && dnf install -y golang
WORKDIR /usr/src/app
COPY . ./
RUN CGO_ENABLED=0 go build -mod=vendor -ldflags="-s -w" -a -installsuffix cgo -o bin/s3manager

FROM harbor.pietschnet.com/redhat/ubi9:latest
WORKDIR /usr/src/app
RUN addgroup -S s3manager && adduser -S s3manager -G s3manager
RUN apk add --no-cache \
  ca-certificates \
  dumb-init
COPY --from=builder --chown=s3manager:s3manager /usr/src/app/bin/s3manager ./
USER s3manager
EXPOSE 8080
ENTRYPOINT [ "/usr/bin/dumb-init", "--" ]
CMD [ "/usr/src/app/s3manager" ]
