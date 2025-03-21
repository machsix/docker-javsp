FROM python:3.12-slim AS builder

WORKDIR /app

ENV PATH=/root/.local/bin:$PATH
RUN pip install pipx && \
    pipx ensurepath && \
    pipx install poetry
RUN apt update && apt install -y git

COPY . .

RUN poetry self add poetry-dynamic-versioning && \
    poetry config virtualenvs.in-project true && \
    poetry install && \
    rm -rf /app/.git

FROM python:3.12-slim as runner

ARG BUILD_DATE
ARG VCS_REF

LABEL build_version="Build-date:- ${BUILD_DATE} SHA:- ${VCS_REF}"

WORKDIR /app

ENV PUID=1000 \
    PGID=1000 \
    CONFIG_PATH=/config.yml

RUN apt update && apt install -y gosu && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/ /app/

RUN rm /app/config.yml

CMD ["/bin/sh", "-c", "gosu \"${PUID}:${PGID}\" /app/.venv/bin/javsp -c \"${CONFIG_PATH}\""]
