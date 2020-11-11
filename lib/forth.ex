defmodule Forth do
  @moduledoc """
  Implements a simple Forth evaluator
  """

  defstruct [stack: [], dict: %{}, startdef: false]

  @type t :: %Forth{stack: [stack()], dict: %{}, startdef: boolean}

  @type stack :: integer | t()

  @doc """
  Create a new evaluator.
  """
  @spec new() :: t()
  def new() do
    %Forth{}
  end

  @doc """
  Evaluate an input string, updating the evaluator state.
  """
  @spec eval(t(), String.t()) :: t()
  def eval(forth, str) do
    {:ok, tokens, _} = str |> to_charlist() |> :forth_lexer.string()
    eval_tokens(forth, tokens)
  end

  @doc """
  Return the current stack as a string with the element on top of the stack
  being the rightmost element in the string.
  """
  @spec format_stack(t()) :: String.t()
  def format_stack(forth) do
    forth.stack |> Enum.reverse() |> Enum.join(" ")
  end

  # Evaluates a list of tokens from the lexer
  #
  # If `startdef` in the Forth struct is true, instead of evaluating the
  # tokens, it pushes them onto the list at the head of the stack.
  @spec eval_tokens(t(), [any]) :: t()

  # Empty token list
  defp eval_tokens(forth, []) do
    forth
  end

  # int
  defp eval_tokens(forth = %Forth{startdef: true, stack: [command_def | stack]}, [token = {:int, _, _} | rest]) do
    eval_tokens(%Forth{forth | stack: [[token | command_def] | stack]}, rest)
  end
  defp eval_tokens(forth = %Forth{startdef: false, stack: stack}, [{:int, _, int} | rest]) do
    eval_tokens(%Forth{forth | stack: [int | stack]}, rest)
  end

  # op
  defp eval_tokens(%Forth{startdef: true, stack: [command_def | stack]}, [token = {:op, _, _} | rest]) do
    eval_tokens(%Forth{startdef: true, stack: [[token | command_def] | stack]}, rest)
  end
  defp eval_tokens(%Forth{startdef: false, stack: stack}, [{:op, _, op} | rest]) do
    eval_tokens(%Forth{startdef: false, stack: eval_operator(op, stack)}, rest)
  end

  # id
  defp eval_tokens(forth = %Forth{startdef: true, stack: [command_def | stack]}, [token = {:id, _, _} | rest]) do
    eval_tokens(%Forth{forth | stack: [[token | command_def] | stack]}, rest)
  end
  defp eval_tokens(forth = %Forth{startdef: false}, [{:id, _, command} | rest]) do
    to_string(command) |> String.downcase() |> execute_command(forth) |> eval_tokens(rest)
  end

  # startdef
  defp eval_tokens(%Forth{startdef: false, stack: stack}, [{:startdef, _} | rest]) do
    eval_tokens(%Forth{startdef: true, stack: [[] | stack]}, rest)
  end

  # enddef
  defp eval_tokens(%Forth{startdef: true, stack: [command_def | stack]}, [{:enddef, _} | rest]) do
    case Enum.reverse(command_def) do
      [{:id, _, name} | tokens] ->
        eval_tokens(%Forth{startdef: false, stack: stack, dict: %{to_string(name) => tokens}}, rest)
      [{:int, _, int} | _] -> raise Forth.InvalidWord, word: int
    end
  end

  # Evaluates a binary operator in the context of a stack
  @spec eval_operator(charlist, [any]) :: [any]

  # addition
  defp eval_operator('+', [y | [x | rest]]) do
    [x + y | rest]
  end

  # subtraction
  defp eval_operator('-', [y | [x | rest]]) do
    [x - y | rest]
  end

  # multiplication
  defp eval_operator('*', [y | [x | rest]]) do
    [x * y | rest]
  end

  # integer division
  defp eval_operator('/', [0 | _]) do
    raise Forth.DivisionByZero
  end
  defp eval_operator('/', [y | [x | rest]]) do
    [div(x, y) | rest]
  end

  defp execute_command("dup", %Forth{stack: []}) do
    raise Forth.StackUnderflow
  end
  defp execute_command("dup", forth) do
    %Forth{forth | stack: [hd(forth.stack) | forth.stack]}
  end

  defp execute_command("drop", %Forth{stack: []}) do
    raise Forth.StackUnderflow
  end
  defp execute_command("drop", forth) do
    %Forth{forth | stack: tl(forth.stack)}
  end

  defp execute_command("swap", %Forth{stack: []}) do
    raise Forth.StackUnderflow
  end
  defp execute_command("swap", %Forth{stack: [_]}) do
    raise Forth.StackUnderflow
  end
  defp execute_command("swap", forth) do
    [y | [x | rest]] = forth.stack
    %Forth{forth | stack: [x | [y | rest]]}
  end

  defp execute_command("over", %Forth{stack: []}) do
    raise Forth.StackUnderflow
  end
  defp execute_command("over", %Forth{stack: [_]}) do
    raise Forth.StackUnderflow
  end
  defp execute_command("over", forth) do
    [_ | [x | _]] = forth.stack
    %Forth{forth | stack: [x | forth.stack]}
  end

  defp execute_command(command, forth) do
    case forth.dict do
      %{^command => tokens} -> eval_tokens(forth, tokens)
      _ -> raise Forth.UnknownWord, word: command
    end
  end

  defmodule StackUnderflow do
    defexception []
    def message(_), do: "stack underflow"
  end

  defmodule InvalidWord do
    defexception word: nil
    def message(e), do: "invalid word: #{inspect(e.word)}"
  end

  defmodule UnknownWord do
    defexception word: nil
    def message(e), do: "unknown word: #{inspect(e.word)}"
  end

  defmodule DivisionByZero do
    defexception []
    def message(_), do: "division by zero"
  end
end
