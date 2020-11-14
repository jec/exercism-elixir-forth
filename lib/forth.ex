defmodule Forth do
  @moduledoc """
  Implements a simple Forth evaluator
  """

  defstruct [stack: [], dict: %{}, startdef: false]

  @type t :: %Forth{stack: stack(), dict: %{}, startdef: boolean}

  @type state :: :none | :int

  @type stack :: [integer | t()]

  @type binary_op :: ?+ | ?- | ?* | ?/

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

  # int
  defp eval_token(token = {:int, _}, forth = %Forth{startdef: true, stack: [command_def | stack]}) do
    %Forth{forth | stack: [[token | command_def] | stack]}
  end
  defp eval_token({:int, int}, forth = %Forth{startdef: false, stack: stack}) do
    %Forth{forth | stack: [int | stack]}
  end

  # op
  defp eval_token(token = {:op, _}, forth = %Forth{startdef: true, stack: [command_def | stack]}) do
    %Forth{forth | stack: [[token | command_def] | stack]}
  end
  defp eval_token({:op, op}, forth = %Forth{startdef: false, stack: stack}) do
    %Forth{forth | stack: eval_operator(op, stack)}
  end

  # id
  defp eval_token(token = {:id, _}, forth = %Forth{startdef: true, stack: [command_def | stack]}) do
    %Forth{forth | stack: [[token | command_def] | stack]}
  end
  defp eval_token({:id, command}, forth = %Forth{startdef: false}) do
    String.downcase(command) |> execute_command(forth)
  end

  # startdef
  defp eval_token({:startdef, _}, forth = %Forth{startdef: false, stack: stack}) do
    %Forth{forth | startdef: true, stack: [[] | stack]}
  end

  # enddef
  defp eval_token({:enddef, _}, %Forth{startdef: true, stack: [command_def | stack], dict: dict}) do
    case Enum.reverse(command_def) do
      [{:id, name} | tokens] ->
        %Forth{startdef: false, stack: stack, dict: Map.put(dict, name, tokens)}
      [{:int, int} | _] -> raise Forth.InvalidWord, word: int
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

  # Evaluates a binary operator in the context of a stack
  @spec eval_operator(binary_op(), stack()) :: stack()

  # addition
  defp eval_operator(?+, [y | [x | rest]]) do
    [x + y | rest]
  end

  # subtraction
  defp eval_operator(?-, [y | [x | rest]]) do
    [x - y | rest]
  end

  # multiplication
  defp eval_operator(?*, [y | [x | rest]]) do
    [x * y | rest]
  end

  # integer division
  defp eval_operator(?/, [0 | _]) do
    raise Forth.DivisionByZero
  end
  defp eval_operator(?/, [y | [x | rest]]) do
    [div(x, y) | rest]
  end

  # Executes a named command
  @spec execute_command(String.t(), t()) :: t()

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
