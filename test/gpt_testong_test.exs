defmodule GptTestongTest do
  use ExUnit.Case

  test "test_run_test" do
    test_file_path = Application.get_env(:gpt_testong, :generated_module_test_path)

    %{test_successful: test_successful, test_stacktrace: test_stacktrace} =
      GptTestong.run_test(test_file_path)

    assert test_successful == false
    assert test_stacktrace == "  1) test greets the world (GeneratedModuleTest)\n     priv/generated_project_test/test/generated_module_test.exs:4\n     ** (UndefinedFunctionError) function GeneratedModle.to_be_created/0 is undefined (module GeneratedModle is not available)\n     code: assert GeneratedModle.to_be_created() == :ok\n     stacktrace:\n       GeneratedModle.to_be_created()\n       priv/generated_project_test/test/generated_module_test.exs:5: (test)"
  end

  test "store_gpt_response" do
    content = Enum.random(1..100)
    response = "something before@@@#MODULE_START\n#{content}\n@@@something after"
    assert GptTestong.store_gpt_response(response) == :ok
    assert File.read!(Application.get_env(:gpt_testong, :generated_module_path)) == "#{content}\n"
  end

  test "build_prompt" do
    prompt = "prompt"
    test_results = "test_results"
    test_body = "test_body"
    generated_code = "generated_code"
    format = "format"

    full_promt = GptTestong.build_promt([prompt, test_results, test_body, generated_code, format])

    assert full_promt == "START_OF_PROMT\nprompt\n\ntest_results\n\ntest_body\n\ngenerated_code\n\nformat\nEND_OF_PROMT"
  end
end
