ARG VERSION

###Build
# distroless has no shell or package manager, so the build stage uses the debian release it is built from
FROM --platform=${BUILDPLATFORM} debian:13.7-slim AS build
ARG VERSION \
    BUILDPLATFORM \
    TARGETPLATFORM

WORKDIR /
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates wget jq && \
    rm -rf /var/lib/apt/lists/* && \
    VERSION=${VERSION#v} && \
    case "${TARGETPLATFORM}" in \
        linux/amd64) PLATFORM=linux-amd64 ;; \
        linux/arm64) PLATFORM=linux-arm64 ;; \
        linux/arm/v7) PLATFORM=linux-armv7l ;; \
        *) echo "Unsupported platform: ${TARGETPLATFORM}" && exit 1 ;; \
    esac && \
    case "${VERSION}" in \
        *-*) TRACK=beta ;; \
        *) TRACK=stable ;; \
    esac && \
    echo "PLATFORM: $PLATFORM; TRACK: $TRACK; VERSION: $VERSION" && \
    ASSETURL=$(wget -qO- "https://releases.autodarts.com/headless/downloads/downloads.${TRACK}.json" | jq -r --arg PLATFORM "${PLATFORM}" --arg VERSION "${VERSION}" '.platforms[$PLATFORM][]? | select(.version == $VERSION) | .files[] | select(.kind == "archive") | .url' | head -n 1) && \
    echo "ASSETURL: $ASSETURL" && \
    [ -n "$ASSETURL" ] && \
    wget "$ASSETURL" && \
    mkdir /autodarts && \
    tar -vxzf $(basename $ASSETURL) -C /autodarts --strip-components=1 && \
    rm $(basename $ASSETURL) && \
    test -x /autodarts/autodarts

###Run
FROM gcr.io/distroless/cc-debian13:latest@sha256:159783207c2cd44c2aa5715961d13c8612368ac9bd450f887e3f08fc8ea461e3

WORKDIR /usr/local/bin/autodarts
COPY --from=build /autodarts/ .

#expose the autodarts port
EXPOSE 3180

ENTRYPOINT ["./autodarts"]
CMD ["run"]
