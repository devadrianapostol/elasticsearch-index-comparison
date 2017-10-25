%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/"],
        excluded: [~r"/_build/", ~r"/deps/"]
      },
      requires: [],
      strict: true,
      color: true,
      checks: [
        {Credo.Check.Design.TagTODO, false},
        {Credo.Check.Readability.MaxLineLength, priority: :high, max_length: 120}
      ]
    }
  ]
}
