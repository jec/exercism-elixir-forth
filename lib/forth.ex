defmodule Forth do
  @moduledoc """
  Implements a simple Forth evaluator
  """

  @default_dict %{
    "dup" => [stackop: :dup],
    "drop" => [stackop: :drop],
    "swap" => [stackop: :swap],
    "over" => [stackop: :over]
  }

  defstruct [stack: [], dict: @default_dict, startdef: false]

  @type t :: %Forth{stack: stack(), dict: %{}, startdef: boolean}

  @type state :: :none | :int

  @type stack :: [integer | t()]

  @type binary_op :: ?+ | ?- | ?* | ?/

  @type stack_op :: :dup | :drop | :swap | :over

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
  def eval(forth, <<>>) do
    forth
  end
  def eval(forth, str) do
    {token_type, value, next_str} = Forth.Tokenizer.eval(str)
    next_forth = eval_token({token_type, value}, forth)
    eval(next_forth, next_str)
  end

  @doc """
  Return the current stack as a string with the element on top of the stack
  being the rightmost element in the string.
  """
  @spec format_stack(t()) :: String.t()
  def format_stack(%Forth{stack: stack}) do
    stack |> Enum.reverse() |> Enum.join(" ")
  end

  # Evaluates a token in the context of a Forth struct and returns an updated
  # Forth struct
  @spec eval_token({Forth.Tokenizer.token_type(), any}, t()) :: t()
  defp eval_token({:int, int}, forth = %Forth{startdef: false, stack: stack}) do
    %Forth{forth | stack: [int | stack]}
  end
  defp eval_token({:op, op}, forth = %Forth{startdef: false, stack: stack}) do
    %Forth{forth | stack: eval_operator(op, stack)}
  end
  defp eval_token({:id, command}, forth = %Forth{startdef: false}) do
    String.downcase(command) |> execute_command(forth)
  end
  defp eval_token({:stackop, op}, forth = %Forth{startdef: false, stack: stack}) do
    %Forth{forth | stack: eval_stackop(op, stack)}
  end
  defp eval_token({:startdef, _}, forth = %Forth{startdef: false, stack: stack}) do
    # Push an empty list onto the stack, which we will use to collect the
    # tokens until we encounter an :enddef.
    %Forth{forth | startdef: true, stack: [[] | stack]}
  end
  defp eval_token({:enddef, _}, %Forth{startdef: true, stack: [command_def | stack], dict: dict}) do
    # Reverse the list that contains the tokens. Now the first token is the
    # name of the command to be defined, and the remaining tokens are the
    # definition.
    case Enum.reverse(command_def) do
      [{:id, name} | tokens] ->
        %Forth{startdef: false, stack: stack, dict: Map.put(dict, name, tokens)}
      [{:int, int} | _] -> raise Forth.InvalidWord, word: int
    end
  end
  # any other token when startdef is true
  defp eval_token(token, forth = %Forth{startdef: true, stack: [command_def | stack]}) do
    %Forth{forth | stack: [[token | command_def] | stack]}
  end

  # Evaluates a binary operator in the context of a stack
  @spec eval_operator(binary_op(), stack()) :: stack()
  defp eval_operator(?+, [y | [x | rest]]) do
    [x + y | rest]
  end
  defp eval_operator(?-, [y | [x | rest]]) do
    [x - y | rest]
  end
  defp eval_operator(?*, [y | [x | rest]]) do
    [x * y | rest]
  end
  defp eval_operator(?/, [0 | _]) do
    raise Forth.DivisionByZero
  end
  defp eval_operator(?/, [y | [x | rest]]) do
    [div(x, y) | rest]
  end

  # Evaluates a built-in stack operator in the context of a stack
  @spec eval_stackop(stack_op(), stack()) :: stack()
  defp eval_stackop(_, []) do
    raise Forth.StackUnderflow
  end
  defp eval_stackop(:dup, [head | tail]) do
    [head | [head | tail]]
  end
  defp eval_stackop(:drop, [_ | tail]) do
    tail
  end
  defp eval_stackop(:swap, [_]) do
    raise Forth.StackUnderflow
  end
  defp eval_stackop(:swap, [y | [x | rest]]) do
    [x | [y | rest]]
  end
  defp eval_stackop(:over, [_]) do
    raise Forth.StackUnderflow
  end
  defp eval_stackop(:over, stack = [_ | [x | _]]) do
    [x | stack]
  end

  # Executes a named command
  @spec execute_command(String.t(), t()) :: t()
  defp execute_command(command, forth) do
    case forth.dict do
      %{^command => tokens} -> eval_tokens(forth, tokens)
      _ -> raise Forth.UnknownWord, word: command
    end
  end

  # Recursively evaluates a list of tokens
  @spec eval_tokens(t(), [{Forth.Tokenizer.token_type(), any}]) :: t()
  defp eval_tokens(forth, []) do
    forth
  end
  defp eval_tokens(forth, [token | rest]) do
    next_forth = eval_token(token, forth)
    eval_tokens(next_forth, rest)
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
