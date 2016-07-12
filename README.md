# IndexComparison

This tool can help you to compare ElasticSearch indexes when you're doing some refactoring in mappings.

## Install guide

You need Erlang and Elixir to be installed on your machine.
For OS X install commands look like these:

```bash
brew install erlang elixir
mix deps.get
mix escript.build
```

Usage:

```bash
./index_comparison --old-dump <path> --new-dump <path> --timeout <number> --check-only<comma-separated field names>
```

You must provide `--old-dump` and `--new-dump` parameters, `timeout` and `check-only` are optional.

## Dumps

Of course you need to make these dumps somehow. I use `elasticdump` tool for that. You need Node.js for it.

```bash
brew install node
npm install -g elasticdump
```

Usage:

```bash
elasticdump --input=http://<elasticsearch-url(localhost:9200)>/<index-name> --output=dump_new.json --type=data --limit=<batch-size, I use 100000>
```

It is my personal tool and provided as is. If you have any issues - please let me know.

## Known issues

1. It can be working bad with datetimes if they are stored in different formats. Because it doesn't parse them and compare strings. It's done for performance purposes. Maybe will be changed in future.
