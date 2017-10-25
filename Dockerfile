FROM elixir:1.5.2

COPY ./ /app
WORKDIR /app

ENV MIX_ENV prod

RUN mix local.hex --force
RUN mix deps.get
RUN mix escript.build
ENTRYPOINT ["/app/index_comparison"]
