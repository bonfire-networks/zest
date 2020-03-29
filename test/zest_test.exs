# Zest - a fresh approach to testing
#
# Copyright (c) 2020 James Laver
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
defmodule ZestTest do
  use ExUnit.Case
  doctest Zest
  import Zest

  @tag :manual
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
