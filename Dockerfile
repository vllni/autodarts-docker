ARG VERSION

###Build
FROM --platform=${BUILDPLATFORM} alpine:3.22.4 AS build
ARG VERSION \
    BUILDPLATFORM \
    TARGETPLATFORM

WORKDIR /
RUN apk update && \
    apk add wget tar jq && \
    PLATFORM=$(echo ${TARGETPLATFORM} | cut -d'/' -f1) && \
    ARCH=$(echo ${TARGETPLATFORM} | cut -d'/' -f2) && \
    echo "PLATFORM: $PLATFORM; ARCH: $ARCH; VERSION: $VERSION" && \
    ASSETURL=$(wget -qO- "https://get.autodarts.io/detection/latest/${PLATFORM}/${ARCH}/RELEASES.json" | jq -r --arg VERSION "${VERSION}" '.releases[] | select(.version == $VERSION) | .url') && \
    echo "ASSETURL: $ASSETURL" && \
    wget "$ASSETURL" && \
    tar -vxf $(basename $ASSETURL) && \
    rm $(basename $ASSETURL)

###Run
FROM alpine:latest

WORKDIR /usr/local/bin/autodarts
COPY --from=build /autodarts .
RUN chmod +x ./autodarts

#expose the autodarts port
EXPOSE 3180

CMD ["./autodarts"]
