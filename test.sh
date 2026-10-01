#!/bin/sh
set -eu
cd "$(dirname "$0")"
test_binary=$(mktemp -t mightyscroll-tests)
trap 'rm -f "$test_binary"' EXIT
swiftc Sources/ScrollTransform.swift Sources/HIDBridge.swift Sources/PulseAccelerator.swift Sources/MomentumState.swift Sources/ScrollMomentumEngine.swift Tests/ScrollTransformTests.swift -o "$test_binary"
"$test_binary"
