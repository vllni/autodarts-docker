ARG VERSION

###Build
FROM --platform=${BUILDPLATFORM} alpine:3.24.2 AS build
ARG VERSION \
    BUILDPLATFORM \
    TARGETPLATFORM

WORKDIR /
RUN apk update && \
    apk add wget tar jq && \
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
FROM gcr.io/distroless/cc-debian13:latest@sha256:4594d59540d1948417f6ca2829ddd9294493a7c68b7528f4dd459de7f203a750

WORKDIR /usr/local/bin/autodarts
COPY --from=build /autodarts/ .

#expose the autodarts port
EXPOSE 3180

ENTRYPOINT ["./autodarts"]
CMD ["run"]
