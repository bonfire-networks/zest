# Zest

A fresh approach to testing.

## Usage

Installation:

```elixir
{:zest, "~> 0.1.2"}
```

Example (taken from our test suite):

```elixir
defmodule MyTest do
  use ExUnit.Case
  import Zest
  
  test "scope fails spectacularly" do
    scope [this: %{is: :a}, test: :case] do
      scope [error: :this_should_not_show] do
      end
      scope [the: :order, must: :be_correct] do
        scope [to: :pass], assert(true == false)
      end
    end
  end

end
```

Output:

```
Zest Context:
* this: %{is: :a}
* test: :case
* the: :order
* must: :be_correct
* to: :pass


  1) test scope fails spectacularly (ZestTest)
     test/zest_test.exs:7
     Assertion with == failed
     code:  assert true == false
     left:  true
     right: false
     stacktrace:
       (zest 0.1.0) lib/zest.ex:52: Zest.in_scope/2
       (zest 0.1.0) lib/zest.ex:47: anonymous fn/1 in Zest.in_scope/2
       (zest 0.1.0) lib/zest.ex:113: Zest.intercept/2
       test/zest_test.exs:8: (test)
```

## Contributing

Contributions are welcome, even just doc fixes or suggestions.

This project has adopted a [Code of Conduct](CONDUCT.md) based on the
Contributor Covenant. Please be nice when interacting with the community.

## Copyright and License

Copyright (c) 2020 James Laver

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

