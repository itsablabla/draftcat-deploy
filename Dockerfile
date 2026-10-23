# Draftcat on Hostim — builds the engine from source so the image can run an
# entrypoint (the upstream distroless image cannot exec a shell, which blocks
# injecting the Gmail token at boot). No secrets in this repo: the Gmail token
# arrives base64-encoded in the GMAIL_TOKEN_JSON env var set on the Hostim app.
FROM golang:1.25-alpine AS build
WORKDIR /src
RUN apk add --no-cache git ca-certificates
RUN git clone --depth 1 --branch v0.13.0 https://github.com/renezander030/draftcat.git .
COPY config.yaml /src/config.yaml
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/draftcat .

FROM alpine:3.20
RUN apk add --no-cache ca-certificates tzdata
COPY --from=build /out/draftcat /usr/local/bin/draftcat
COPY config.yaml /work/config.yaml
COPY --from=build /src/skills /work/skills
COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh
WORKDIR /work
EXPOSE 8088
ENTRYPOINT ["/entrypoint.sh"]
