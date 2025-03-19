FROM almalinux:9.5 AS builder
USER root
COPY ./tools/go1.24.1.linux-amd64.tar.gz ./
RUN dnf install -y tar gzip && rm -rf /usr/local/go && tar -C /usr/local/ -xzf go1.24.1.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin
RUN go version && dnf upgrade -y 
WORKDIR /usr/src/app
COPY . ./
RUN CGO_ENABLED=0 go build -mod=vendor -ldflags="-s -w" -a -installsuffix cgo -o bin/s3manager

FROM almalinux:9.5
WORKDIR /usr/src/app
RUN groupadd s3manager && useradd -M -g s3manager -s /sbin/nologin s3manager
RUN dnf install epel-release -y && dnf clean all && dnf makecache && dnf update -y && dnf install -y dumb-init
COPY --from=builder --chown=s3manager:s3manager /usr/src/app/bin/s3manager ./
USER s3manager
EXPOSE 8080
ENTRYPOINT [ "/usr/bin/dumb-init", "--" ]
CMD [ "/usr/src/app/s3manager" ]
