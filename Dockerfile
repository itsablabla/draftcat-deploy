# Hostim build wrapper: pinned official draftcat image + a config.yaml
# whose provider points at the Manifest gateway (app.manifest.build/v1) with
# model "auto". Credentials stay in Hostim app env, never in this repo.
FROM ghcr.io/renezander030/draftcat:0.13.0
COPY config.yaml /work/config.yaml
