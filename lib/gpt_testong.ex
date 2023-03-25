defmodule GptTestong do
  @moduledoc """
  This module utilizes OpenAI GPT API to generate code based on the test,
  recursively generating code until the test passes.
  """

  defmodule HTTPClient do
    @moduledoc """
    HTTP client for GPT API
    """

    use Tesla

    @open_ai_secret_key Application.compile_env(:gpt_testong, :open_ai_secret_key)
    plug(Tesla.Middleware.BaseUrl, "https://api.openai.com/")
    plug(Tesla.Middleware.JSON)
    plug(Tesla.Middleware.BearerAuth, token: @open_ai_secret_key)

    @doc """
    Makes a request to OpenAI GPT API using secret key
    returns text response as a tuple {:ok, body} or error tuple {:error, "failed"}
    if the response status code was not 200
    """
    @spec make_gpt_request(binary) :: {:ok, binary} | {:error, binary}
    def make_gpt_request(request_body) do
      body = %{
       prompt: request_body,
       temperature: 0.1,
       top_p: 1,
       max_tokens: 2000,
       stop: "",
       model: "text-davinci-003"
      }
      resp = post!("/v1/completions", body)

      case resp do
        %{status: 200, body: body} ->
          {:ok, Enum.at(body["choices"], 0)["text"]}

        %{status: status, body: body} ->
          {:error, "GPT API request failed with status code #{status} and body #{body}"}
      end
    end

    def list_models() do
      get!("/v1/models").body["data"] |> Enum.map(fn model -> model["id"] end)
    end
  end

  @doc """
  Read a content of the module containing tests
  """
  @spec parse_test_body(binary) :: binary
  def parse_test_body(test_module_path) do
    File.read!(test_module_path)
  end

  @doc """
   Takes test text as an input
   send a request to  GPT API with the TEST body + prompt + already generated code + previous test result (stacktrace and binary test result)
   prompt contains a request to generate the minimum amount of code so that the test passes, asking to correct the errors until the test passes
   prompt as  a format GPT should follow so that our application can extract produced module from the response
  """
  @spec send_test_request() :: :ok
  def send_test_request do
    test_module_path = Application.get_env(:gpt_testong, :generated_module_test_path)
    test_body = "Test body: " <> parse_test_body(test_module_path)

    %{test_successful: test_successful, test_stacktrace: test_stacktrace} =
      run_test(test_module_path)

    generated_code =
      "Existing code to be completed: defmodule GeneratedModule do \n @moduledoc \"\"\n \nend"

    test_results =
      "Was test successful? #{test_successful}\nTest failure stacktrace: #{test_stacktrace}"

    prompt =
      "Rewrite existing Elixir code module until the test is successful, use test failure stacktrace to resolve the errors. Recognize a problem in the test and make a generic solution that would work with similar cases. Write as much code as you need."

    format = "Use this format as an answer: @@@#MODULE_START\n<insert module code here>\n@@@"
    full_promt = build_promt([prompt, test_results, test_body, generated_code, format])

    case HTTPClient.make_gpt_request(full_promt) do
      {:ok, body} ->
        store_gpt_response(body)

      {:error, error} ->
        IO.puts("GPT API request failed with error: #{error}")
    end
  end

  @doc """
  Combines test body, test resuults and prompt into a single string.
  Contains format for GPT to follow so that our application can extract produced module from the response.
  """
  def build_promt(chunks) do
    "START_OF_PROMT\n" <>
      Enum.join(chunks, "\n\n") <>
      "\nEND_OF_PROMT"
  end

  @doc """
  Extracts module from the response and stores it in the project lib location
  """
  @spec store_gpt_response(any) :: :ok
  def store_gpt_response(response) do
    body =
      String.split(response, "@@@")
      |> Enum.filter(fn chunk -> String.starts_with?(chunk, "#MODULE_START") end)
      |> Enum.at(0)
      |> String.replace("#MODULE_START\n", "")

    generated_module_path = Application.get_env(:gpt_testong, :generated_module_path)
    :ok = File.write!(generated_module_path, body, [:write, :utf8])

    :ok
  end

  @doc """
  Runs linux CMD to execute the mix test command for the input test_path,
  gets the result, parses the output of the CMD, extracting binary test result and test error if present.
  in the map like this: %{test_successful: false, test_stacktrace: "..."}
  """
  @spec run_test(binary) :: map()
  def run_test(test_file_path) do
    {test_command_output, _status} = System.cmd("mix", ["test", test_file_path])

    test_successful = test_command_output |> String.contains?("0 failures")
    test_stacktrace =
      test_command_output
    |> String.split("\n\n")
    |> Enum.filter(fn chunk -> String.contains?(chunk, "1) test") end)
    |> Enum.at(0)

    %{test_successful: test_successful, test_stacktrace: test_stacktrace}
  end

  # def generate_code_by_test(test_module_path, dest_module_path, test_file_path) do
  # end
end
