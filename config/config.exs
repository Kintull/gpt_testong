import Config

config :tesla, adapter: Tesla.Adapter.Hackney

config :gpt_testong, :generated_module_path, System.fetch_env!("TESTONG_DEV_GENERATED_MODULE_PATH")
config :gpt_testong, :generated_module_test_path, System.fetch_env!("TESTONG_DEV_GENERATED_MODULE_TEST_PATH")
config :gpt_testong, :open_ai_secret_key, System.fetch_env!("TESTONG_OPEN_AI_SECRET_KEY")


import_config "#{config_env()}.exs"
