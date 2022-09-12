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
defmodule Zest do
  @doc """
  Add some debug information to the context for the duration of a
  block or expression. If a `raise`, `throw` or `exit` occurs, the
  context will be pretty printed to the screen to aid with debugging.

  Examples:
    
    ```scope [foo: :bar[, assert(true == false)```

    ```scope [foo: :bar] do
         assert true == false
       end
    ```
  """
  defmacro scope(list, do: block) when is_list(list) do
    quote do
      Zest.in_scope(unquote(list), fn -> unquote(block) end)
    end
  end

  defmacro scope(list, expr) when is_list(list) do
    quote do
      Zest.in_scope(unquote(list), fn -> unquote(expr) end)
    end
  end

  @doc "Wrap a function such that it is as if its body was wrapped in `scope/2`"
  @spec scoped(Keyword.t(), region :: function) :: function
  def scoped(scopes, fun) when is_function(fun) do
    hijack(fun, fn _, args -> in_scope(scopes, fn -> apply(fun, args) end) end)
  end

  @doc """
  Add some debug information to the context for the duration of a
  function's execution. If a `raise`, `throw` or `exit` occurs, the
  context will be pretty printed to the screen to aid with debugging.
  """
  @spec in_scope(Keyword.t(), function) :: term
  def in_scope(scopes, fun) when is_list(scopes) and is_function(fun, 0) do
    old = push_scopes(scopes)

    if old == [] do
      intercept(
        fn ->
          ret = fun.()
          put_scopes([])
          ret
        end,
        rethrowing(fn -> dump_scopes() end)
      )
    else
      ret = fun.()
      put_scopes(old)
      ret
    end
  end

  @doc """
  You take on the role of the `apply` function in this exciting
  function that wraps execution of a function such that your function
  is responsible for calling it.
  """
  @spec hijack(function, jack :: (function, [term] -> term)) :: function
  def hijack(fun, jack) when is_function(fun, 0) and is_function(jack, 2) do
    fn -> jack.(fun, []) end
  end

  def hijack(fun, jack) when is_function(fun, 1) and is_function(jack, 2) do
    fn a -> jack.(fun, [a]) end
  end

  def hijack(fun, jack) when is_function(fun, 2) and is_function(jack, 2) do
    fn a, b -> jack.(fun, [a, b]) end
  end

  def hijack(fun, jack) when is_function(fun, 3) and is_function(jack, 2) do
    fn a, b, c -> jack.(fun, [a, b, c]) end
  end

  def hijack(fun, jack) when is_function(fun, 4) and is_function(jack, 2) do
    fn a, b, c, d -> jack.(fun, [a, b, c, d]) end
  end

  def hijack(fun, jack) when is_function(fun, 5) and is_function(jack, 2) do
    fn a, b, c, d, e -> jack.(fun, [a, b, c, d, e]) end
  end

  def hijack(fun, jack) when is_function(fun, 6) and is_function(jack, 2) do
    fn a, b, c, d, e, f -> jack.(fun, [a, b, c, d, e, f]) end
  end

  def hijack(fun, jack) when is_function(fun, 7) and is_function(jack, 2) do
    fn a, b, c, d, e, f, g -> jack.(fun, [a, b, c, d, e, f, g]) end
  end

  def hijack(fun, jack) when is_function(fun, 8) and is_function(jack, 2) do
    fn a, b, c, d, e, f, g, h -> jack.(fun, [a, b, c, d, e, f, g, h]) end
  end

  def hijack(fun, jack) when is_function(fun, 9) and is_function(jack, 2) do
    fn a, b, c, d, e, f, g, h, i -> jack.(fun, [a, b, c, d, e, f, g, h, i]) end
  end

  @type intercept_type :: :rescue | :catch | :exit
  @type interceptor ::
          (intercept_type, error :: term, maybe_stacktrace :: term -> term)

  @doc "Catches errors and exceptions, invoking an interceptor function"
  @spec intercept(function, interceptor) :: function
  def intercept(fun, interceptor)
      when is_function(fun, 0) and is_function(interceptor, 3) do
    try do
      fun.()
    rescue
      e -> interceptor.(:rescue, e, __STACKTRACE__)
    catch
      e -> interceptor.(:catch, e, nil)
      :exit, e -> interceptor.(:exit, e, nil)
    end
  end

  @doc """
  Wraps an interceptor or nullary function into an interceptor
  function such that after the execution of the provided function, the
  error or exception will be rethrown.
  """
  @spec rethrowing(function) :: function
  def rethrowing(fun) when is_function(fun, 0) do
    rethrowing(fn _, _, _ -> fun.() end)
  end

  def rethrowing(fun) when is_function(fun, 3) do
    fn type, e, stack ->
      fun.(type, e, stack)
      rethrow(type, e, stack)
    end
  end

  @doc "An interceptor function which simply rethrows/reraises/re-exits"
  @spec rethrow(intercept_type, error :: term, maybe_stacktrace :: term) :: none
  def rethrow(:rescue, e, stacktrace), do: reraise(e, stacktrace)
  def rethrow(:catch, e, _), do: throw(e)
  def rethrow(:exit, e, _), do: exit(e)

  @doc """
  Iterates over a collections, calling the provided effectful
  function with each item.
  """
  def each([l | list], fun) do
    scope each: l do
      fun.(l)
      each(list, fun)
    end
  end

  def each(_, _), do: nil

  @doc """
  Iterates over two collections, calling the provided effectful
  function with each pair of items
  """
  def each(a, b, fun) when not is_list(a), do: each(Enum.to_list(a), b, fun)
  def each(a, b, fun) when not is_list(b), do: each(a, Enum.to_list(b), fun)

  def each([a | as], [b | bs], fun) do
    scope each: %{a: a, b: b} do
      fun.(a, b)
      each(as, bs, fun)
    end
  end

  def each(_, _, _), do: nil

  ### implementation

  @scopes_key Zest.Context

  defp get_scopes(), do: Process.get(@scopes_key, [])

  defp put_scopes(scope), do: Process.put(@scopes_key, scope)

  defp push_scopes(new) when is_list(new) do
    old = get_scopes()
    put_scopes(Enum.reduce(new, old, fn {k, v}, acc -> [{k, v} | acc] end))
    old
  end

  defp dump_scopes(scopes \\ get_scopes()) do
    IO.puts("Zest Context:")

    Enum.each(Enum.reverse(scopes), fn {k, v} ->
      IO.puts("* #{k}: #{inspect(v, pretty: true)}")
    end)
  end
end
