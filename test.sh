#!/bin/bash
set -e
# a helper script to run tests in the appropriate directories

# build and run nsqlookupd
echo "building and starting nsqlookupd"
godep go build -o nsqlookupd/nsqlookupd ./nsqlookupd
nsqlookupd/nsqlookupd >/dev/null 2>&1 &
LOOKUPD_PID=$!

# build and run nsqd configured to use our lookupd above
cmd="nsqd/nsqd --data-path=/tmp --lookupd-tcp-address=127.0.0.1:4160 --tls-cert=nsqd/test/cert.pem --tls-key=nsqd/test/key.pem"
echo "building and starting $cmd"
godep go build -o nsqd/nsqd ./nsqd
$cmd >/dev/null 2>&1 &
NSQD_PID=$!

sleep 0.3

cleanup() {
    kill -s TERM $NSQD_PID
    kill -s TERM $LOOKUPD_PID
}
trap cleanup INT TERM EXIT

godep go test -v -timeout 60s ./...

# no tests, but a build is something
for dir in nsqadmin apps/* bench/*; do
    echo "building $dir"
    godep go build -o $dir/$(basename $dir) ./$dir
done
