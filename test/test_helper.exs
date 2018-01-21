defmodule TestHelper do
  require ExUnit.Assertions
  require Poison.Parser

  defmacro structure_tests(file, image) do
    funcs =
      file
      |> File.read!()
      |> Poison.Parser.parse!()
      |> Map.fetch!("commandTests")
      |> Enum.map(fn test_definition ->
        quote do
          test unquote("#{file} : #{test_definition["name"]}") do
            [binary | args] = unquote(test_definition["command"])

            output =
              TestHelper.assert_cmd_succeeds([
                "docker",
                "run",
                "--rm",
                "--entrypoint=#{binary}",
                unquote(image) | args
              ])

            unquote(test_definition["expectedOutput"])
            |> Enum.each(fn expectation ->
              regex = Regex.compile!(expectation)
              assert Regex.match?(regex, output)
            end)
          end
        end
      end)

    {:__block__, [], funcs}
  end

  def assert_cmd_succeeds(cmd = [binary | args], opts \\ []) do
    cmd_str = Enum.join(cmd, " ")
    failure_message = Keyword.get(opts, :message, "Failed command: #{cmd_str}")

    cmd_opts =
      if Keyword.get(opts, :stream, false) do
        [into: IO.stream(:stdio, :line)]
      else
        []
      end

    if Keyword.get(opts, :show, false) do
      IO.puts(cmd_str)
    end

    {output, status} = System.cmd(binary, args, cmd_opts)
    ExUnit.Assertions.assert(status == 0, failure_message)
    output
  end

  def assert_cmd_output(cmd, expectation, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, false)
    timeout = Keyword.get(opts, :timeout, 0)
    show = Keyword.get(opts, :show, false)

    if show do
      cmd |> Enum.join(" ") |> IO.puts()
    end

    expectations = List.wrap(expectation)
    assert_cmd_output(cmd, expectations, nil, nil, timeout, verbose)
  end

  defp assert_cmd_output(cmd = [binary | args], expectations, _actual, _code, timeout, verbose) do
    {actual, code} = System.cmd(binary, args)
    check_cmd_output_expectations(cmd, expectations, expectations, actual, code, timeout, verbose)
  end

  defp check_cmd_output_expectations(_cmd, _expectations, [], actual, 0, _timeout, _verbose),
    do: actual

  defp check_cmd_output_expectations(
         cmd,
         expectations,
         [expectation | rest],
         actual,
         0,
         timeout,
         verbose
       ) do
    if actual =~ expectation do
      check_cmd_output_expectations(cmd, expectations, rest, actual, 0, timeout, verbose)
    else
      assert_cmd_output_next(cmd, expectations, actual, 0, timeout, verbose)
    end
  end

  defp check_cmd_output_expectations(cmd, expectations, _, actual, code, timeout, verbose) do
    assert_cmd_output_next(cmd, expectations, actual, code, timeout, verbose)
  end

  defp assert_cmd_output_next(cmd, expectations, actual, code, timeout, _verbose)
       when timeout <= 0 do
    ExUnit.Assertions.flunk(
      "Expected #{inspect(expectations)} but got #{inspect(actual)}" <>
        " (exit code #{code}) when executing #{inspect(cmd)}"
    )
  end

  defp assert_cmd_output_next(cmd, expectations, actual, code, timeout, verbose) do
    if verbose do
      IO.puts("...expected result did not arrive yet (#{timeout} tries remaining)...")
    end

    Process.sleep(1_000)
    assert_cmd_output(cmd, expectations, actual, code, timeout - 1, verbose)
  end

  def build_docker_image(args \\ [], fun) do
    name = generate_name("test-image")

    try do
      assert_cmd_succeeds(
        ["docker", "build", "--no-cache", "-t", name | args] ++ ["."],
        stream: true,
        show: true
      )

      fun.(name)
    after
      System.cmd("docker", ["rmi", name])
    end
  end

  def run_docker_daemon(args \\ [], fun) do
    name = generate_name("test-container")

    try do
      assert_cmd_succeeds(
        ["docker", "run", "--rm", "--name", name, "-d" | args],
        stream: true,
        show: true
      )

      fun.(name)
    after
      System.cmd("docker", ["kill", name])
    end
  end

  defp generate_name(prefix) do
    number =
      0xFFFFFFFF
      |> :rand.uniform()
      |> Integer.to_string(16)
      |> String.downcase()
      |> String.pad_leading(8, "0")

    "#{prefix}-#{number}"
  end
end

ExUnit.start()
