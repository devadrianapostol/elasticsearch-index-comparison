defmodule IndexComparisonTest do
  use ExUnit.Case
  doctest IndexComparison

  alias Inconsistency.{DifferentValues, DifferentKeys, MissingDocument, DifferentOrder}

  test "parse_dump_entry all fields" do
    dump = ~s({"_id": "123123", "_type": "some_type", "_source": {"a": 1, "b": 2}})
    options = %Options{type_of_checking: :all}
    assert IndexComparison.parse_dump_entry(dump, options) == {"some_type#123123", %{"a" => 1, "b" => 2}}
  end

  test "parse_dump_entry only fields" do
    dump = ~s({"_id": "123123", "_type": "some_type", "_source": {"a": 1, "b": 2}})
    options = %Options{type_of_checking: :only, field_names: ["a"]}
    assert IndexComparison.parse_dump_entry(dump, options) == {"some_type#123123", %{"a" => 1}}
  end

  test "parse_dump_entry except fields" do
    dump = ~s({"_id": "123123", "_type": "some_type", "_source": {"a": 1, "b": 2}})
    options = %Options{type_of_checking: :except, field_names: ["a"]}
    assert IndexComparison.parse_dump_entry(dump, options) == {"some_type#123123", %{"b" => 2}}
  end

  test "load_dump makes a map" do
    dump = ~s(
    {"_id": "2", "_type": "some_type1", "_source": {"a": 1, "b": 2}}
    {"_id": "1", "_type": "some_type1", "_source": {"a": 1, "b": 2}}
    {"_id": "1", "_type": "some_type2", "_source": {"a": 1, "b": 2}}
    )
    file_path = "tmp_dump"
    File.write(file_path, String.trim(dump))
    options = %Options{type_of_checking: :all}
    result = %{"some_type1#2" => %{"a" => 1, "b" => 2},
              "some_type1#1" => %{"a" => 1, "b" => 2},
              "some_type2#1" => %{"a" => 1, "b" => 2}}
    assert IndexComparison.load_dump(file_path, options) == result
    File.rm(file_path)
  end

  test "compare when some ids are absent in new dump" do
    old = %{"some_type1#2" => %{},
            "some_type1#1" => %{},
            "some_type2#1" => %{}}
    new = %{"some_type1#2" => %{},
            "some_type1#1" => %{}}
    assert IndexComparison.compare(old, new, %Options{}) == [%MissingDocument{id: "some_type2#1", where: :new}]
  end

  test "compare when some ids are absent in old dump" do
    old = %{"some_type1#2" => %{},
            "some_type1#1" => %{}}
    new = %{"some_type1#2" => %{},
            "some_type1#1" => %{},
            "some_type2#1" => %{}}
    assert IndexComparison.compare(old, new, %Options{}) == [%MissingDocument{id: "some_type2#1", where: :old}]
  end

  test "compare when both dumps are equal" do
    dump = %{"some_type1#2" => %{}}
    assert IndexComparison.compare(dump, dump, %Options{}) == []
  end

  test "compare when keys are different" do
    old = %{"some_type1#2" => %{"a" => 1, "b" => 3}}
    new = %{"some_type1#2" => %{"a" => 1, "c" => 2}}
    assert IndexComparison.compare(old, new, %Options{}) ==
      [%DifferentKeys{id: "some_type1#2", keys: ["a", "b"], another_keys: ["a", "c"]}]
  end

  test "compare when values are different" do
    old = %{"some_type1#2" => %{"a" => 1, "b" => 3}}
    new = %{"some_type1#2" => %{"a" => 1, "b" => 2}}
    assert IndexComparison.compare(old, new, %Options{}) ==
      [%DifferentValues{id: "some_type1#2", key: "b", value: 3, another_value: 2}]
  end

  test "compare when order of values are different" do
    old = %{"some_type1#2" => %{"a" => [1, 2]}}
    new = %{"some_type1#2" => %{"a" => [2, 1]}}
    assert IndexComparison.compare(old, new, %Options{}) ==
      [%DifferentOrder{id: "some_type1#2", key: "a", values: [1, 2], another_values: [2, 1]}]
  end
end
