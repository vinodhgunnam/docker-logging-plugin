FROM golang:1.9.2 as builder

WORKDIR /go/src/github.com/splunknova/nova-log-plugin/
COPY . /go/src/github.com/splunknova/nova-log-plugin/
RUN cd /go/src/github.com/splunknova/nova-log-plugin && go get
RUN go test .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /bin/nova-log-plugin .

FROM alpine:3.7
RUN apk --no-cache add ca-certificates
COPY --from=builder /bin/nova-log-plugin /bin/
WORKDIR /bin/
ENTRYPOINT [ "/bin/nova-log-plugin" ]
