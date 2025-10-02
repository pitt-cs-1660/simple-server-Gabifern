FROM python:3.12-slim AS builder
ENV PATH="/root/.local/bin:$PATH"
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*
WORKDIR /app

# install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# install dependencies
COPY pyproject.toml README.md ./
RUN uv sync --python 3.12 --no-install-project

# copy source and tests
COPY cc_simple_server ./cc_simple_server
COPY tests ./tests

# install project after source
RUN uv sync --python 3.12

FROM python:3.12-slim AS runtime
ENV PATH="/app/.venv/bin:$PATH"
WORKDIR /app

# copy venv and app code
COPY --from=builder /app/.venv ./.venv
COPY --from=builder /app/cc_simple_server ./cc_simple_server
COPY --from=builder /app/tests ./tests

# security
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000
CMD ["uvicorn", "cc_simple_server.server:app", "--host", "0.0.0.0", "--port", "8000"]
