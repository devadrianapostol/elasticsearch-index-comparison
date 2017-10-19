defmodule IndexComparison.Mixfile do
  use Mix.Project

  def project do
    [app: :index_comparison,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     escript: [main_module: IndexComparison],
     deps: deps(),
     dialyzer: [
      plt_add_deps: :transitive,
      flags: ~w{error_handling race_conditions underspecs unknown
                unmatched_returns}
    ]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :poison]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:poison, "2.1.0"},
      {:credo, "~> 0.8.0", only: [:dev]},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false}
    ]
  end
end
