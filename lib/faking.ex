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
defmodule Zest.Faking do
  @moduledoc "Helpers to make random generator functions more useful in tests"

  @doc """
  Reruns a faker until a predicate passes.
  Default limit is 10 tries.
  """
  def such_that(faker, name, test, limit \\ 10)

  def such_that(faker, name, test, limit)
      when is_integer(limit) and limit > 0 do
    fake = faker.()

    if test.(fake),
      do: fake,
      else: such_that(faker, name, test, limit - 1)
  end

  def such_that(_faker, name, _test, _limit) do
    raise Exception, message: "Tries exceeded: #{name}"
  end

  @doc """
  Reruns a faker until an unseen value has been generated.
  Default limit is 10 tries.
  Stores seen things in the process dict (yes, *that* process dict)
  """
  def unused(faker, name, limit \\ 10)
  def unused(_faker, name, 0), do: raise(Exception, message: "Tries exceeded: #{name}")

  def unused(faker, name, limit) when is_integer(limit) do
    used = get_used(name)
    fake = such_that(faker, name, &(&1 not in used))
    forbid(name, [fake])
    fake
  end

  @doc """
  Partner to `unused`. Adds a list of values to the list of used
  values under a key.
  """
  def forbid(name, values) when is_list(values) do
    set_used(name, values ++ get_used(name))
  end

  @doc """
  Returns the next unused integer id for `name` starting from `start`.
  Permits jumping by artificially increasing start - if start is
  higher than the last used id, it will return start and set it as the
  last used id
  """
  def sequential(name, start) when is_integer(start) do
    val = nextval(get_seq(name, start - 1), start)
    set_seq(name, val)
    val
  end

  @doc false
  def used_key(name), do: {__MODULE__, {:used, name}}
  @doc false
  def get_used(name), do: Process.get(used_key(name), [])
  @doc false
  def set_used(name, used) when is_list(used), do: Process.put(used_key(name), used)

  # support for `sequential/2`

  defp nextval(id, start)
  defp nextval(nil, start), do: start
  defp nextval(id, start) when id < start, do: start
  defp nextval(id, _), do: id + 1

  defp seq_key(name), do: {__MODULE__, {:seq, name}}
  defp get_seq(name, default), do: Process.get(seq_key(name), default)
  defp set_seq(name, seq) when is_integer(seq), do: Process.put(seq_key(name), seq)
end
