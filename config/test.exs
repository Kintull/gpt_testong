import Config

config :gpt_testong, :generated_module_path, System.fetch_env!("TESTONG_TEST_GENERATED_MODULE_PATH")
config :gpt_testong, :generated_module_test_path, System.fetch_env!("TESTONG_TEST_GENERATED_MODULE_TEST_PATH")
