# GptTestong

Making OpenAI GPT-3 or 4 generate code based on unit tests. It uses text-davinci-003 completion model.


## Installation

```
mix deps.get

mix test
```

# Setup 

Copy `vars.sh.example` to `vars.sh` and replace secret variables to match your setup. You need GPT API key for this.

then do

```
source vars.sh 
```

put test body in `priv/generated_project/test/generated_module_test.exs`

execute `mix run -e "GptTestong.send_test_request()"`

check generated result in `priv/generated_project/lib/generated_module.ex`
