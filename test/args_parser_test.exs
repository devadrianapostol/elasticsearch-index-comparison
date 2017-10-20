defmodule ArgsParserTest do
  use ExUnit.Case

  test "valid options" do
    result = ArgsParser.parse(["--old-dump", "some_path", "--new-dump", "another-path"])
    assert {:ok, options} = result
    assert %Options{old_dump_path: "some_path", new_dump_path: "another-path",
                    type_of_checking: :all, field_names: []} == options
  end

  test "valid options with unknown keys" do
    result = ArgsParser.parse(["--old-dump", "some_path",
                               "--new-dump", "another-path",
                               "--another-option", "some-value"])
    assert {:ok, options} = result
    assert %Options{old_dump_path: "some_path", new_dump_path: "another-path",
                    type_of_checking: :all, field_names: []} == options
  end

  test "all options are passed" do
    result = ArgsParser.parse(["--old-dump", "some_path",
                               "--new-dump", "another-path",
                               "--only-fields", "a,b,c"])
    assert {:ok, options} = result
    assert %Options{old_dump_path: "some_path", new_dump_path: "another-path",
                    type_of_checking: :only, field_names: ["a", "b", "c"]} == options
  end

  test "all options are passed with except field names" do
    result = ArgsParser.parse(["--old-dump", "some_path",
                               "--new-dump", "another-path",
                               "--except-fields", "a,b,c"])
    assert {:ok, options} = result
    assert %Options{old_dump_path: "some_path", new_dump_path: "another-path",
                    type_of_checking: :except, field_names: ["a", "b", "c"]} == options
  end

  test "invalid options" do
    result = ArgsParser.parse(["--old-dump", "some_path"])
    assert {:error, _} = result
  end
end
