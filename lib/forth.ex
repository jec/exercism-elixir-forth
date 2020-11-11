defmodule Forth do
  @moduledoc """
    Implements a simple Forth evaluator

    States:
    * none -- not building anything
    * int -- building an integer
    * identifier -- building an identifier
    * define -- defining a new command
  """

  defstruct [state: :none, buf: "", stack: []]

  @type t :: %Forth{state: state(), buf: String.t(), stack: [stack()]}

  @type state :: :none | :int

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

  ### State: none ###

  # Input: end-of-string
  # Output: return the struct
  def eval(forth = %Forth{state: :none}, <<>>) do
    forth
  end

  # Input: digit
  # Output: create buffer with digit as initial value
  # Next state: int
  def eval(%Forth{state: :none, stack: stack}, <<ch::utf8, rest::binary>>) when ?0 <= ch and ch <= ?9 do
    eval(%Forth{state: :int, buf: <<ch>>, stack: stack}, rest)
  end

  # Input: non-printing char or space
  # Output: no-op
  # Next state: same state (none)
  def eval(forth = %Forth{state: :none}, <<ch::utf8, rest::binary>>) when ch <= 32 or ch == ?  do
    eval(forth, rest)
  end

  # Input: addition operator
  # Output: pop 2 values from stack; execute operator; push result onto stack
  # Next state: same state (none)
  def eval(%Forth{state: :none, stack: [y | [x | stack]]}, <<ch::utf8, rest::binary>>) when ch == ?+ do
    eval(%Forth{state: :none, buf: nil, stack: [x + y | stack]}, rest)
  end

  # Input: subtraction operator
  # Output: pop 2 values from stack; execute operator; push result onto stack
  # Next state: same state (none)
  def eval(%Forth{state: :none, stack: [y | [x | stack]]}, <<ch::utf8, rest::binary>>) when ch == ?- do
    eval(%Forth{state: :none, buf: nil, stack: [x - y | stack]}, rest)
  end

  # Input: multiplication operator
  # Output: pop 2 values from stack; execute operator; push result onto stack
  # Next state: same state (none)
  def eval(%Forth{state: :none, stack: [y | [x | stack]]}, <<ch::utf8, rest::binary>>) when ch == ?* do
    eval(%Forth{state: :none, buf: nil, stack: [x * y | stack]}, rest)
  end

  # Input: division operator
  # Output: pop 2 values from stack; execute operator; push result onto stack
  # Next state: same state (none)
  def eval(%Forth{state: :none, stack: [y | _]}, <<ch::utf8, _::binary>>) when ch == ?/ and y == 0 do
    raise Forth.DivisionByZero
  end
  def eval(%Forth{state: :none, stack: [y | [x | stack]]}, <<ch::utf8, rest::binary>>) when ch == ?/ do
    eval(%Forth{state: :none, buf: nil, stack: [div(x, y) | stack]}, rest)
  end

  # Input: other character
  # Output: create buffer with character as initial value
  # Next state: identifier
  def eval(%Forth{state: :none, stack: stack}, <<ch::utf8, rest::binary>>) do
    eval(%Forth{state: :identifier, buf: <<ch::utf8>>, stack: stack}, rest)
  end

  ### State: int ###

  # Input: end-of-string
  # Output: push integer onto stack; return the struct
  def eval(%Forth{state: :int, buf: buf, stack: stack}, <<>>) do
    %Forth{state: :none, buf: nil, stack: [String.to_integer(buf) | stack]}
  end

  # Input: digit
  # Output: append digit to buffer
  # Next state: same state (int)
  def eval(%Forth{state: :int, buf: buf, stack: stack}, <<ch::utf8, rest::binary>>) when ?0 <= ch and ch <= ?9 do
    eval(%Forth{state: :int, buf: buf <> <<ch>>, stack: stack}, rest)
  end

  # Input: non-printing char or space
  # Output: push integer onto stack
  # Next state: none
  def eval(%Forth{state: :int, buf: buf, stack: stack}, <<ch::utf8, rest::binary>>) when ch <= 32 or ch == ?  do
    eval(%Forth{state: :none, buf: nil, stack: [String.to_integer(buf) | stack]}, rest)
  end

  ### State: identifier ###

  # Input: end-of-string
  # Output: apply command to stack; return the struct
  def eval(%Forth{state: :identifier, buf: command, stack: stack}, <<>>) do
    %Forth{state: :none, buf: nil, stack: execute_command(String.downcase(command), stack)}
  end

  # Input: non-printing char or space
  # Output: apply command to stack
  # Next state: none
  def eval(%Forth{state: :identifier, buf: command, stack: stack}, <<ch::utf8, rest::binary>>) when ch <= 32 or ch == ?  do
    eval(%Forth{state: :none, buf: nil, stack: execute_command(command, stack)}, rest)
  end

  # Input: other character
  # Output: append character to buffer
  # Next state: same state (identifier)
  def eval(%Forth{state: :identifier, buf: buf, stack: stack}, <<ch::utf8, rest::binary>>) do
    eval(%Forth{state: :identifier, buf: buf <> <<ch::utf8>>, stack: stack}, rest)
  end

  @doc """
  Return the current stack as a string with the element on top of the stack
  being the rightmost element in the string.
  """
  @spec format_stack(t()) :: String.t()
  def format_stack(%Forth{stack: stack}) do
    stack |> Enum.reverse() |> Enum.join(" ")
  end

  defp execute_command("dup", []) do
    raise Forth.StackUnderflow
  end
  defp execute_command("dup", stack = [x | _]) do
    [x | stack]
  end

  defp execute_command("drop", []) do
    raise Forth.StackUnderflow
  end
  defp execute_command("drop", [_ | rest]) do
    rest
  end

  defp execute_command("swap", []) do
    raise Forth.StackUnderflow
  end
  defp execute_command("swap", [_]) do
    raise Forth.StackUnderflow
  end
  defp execute_command("swap", [y | [x | rest]]) do
    [x | [y | rest]]
  end

  defp execute_command("over", []) do
    raise Forth.StackUnderflow
  end
  defp execute_command("over", [_]) do
    raise Forth.StackUnderflow
  end
  defp execute_command("over", stack = [_ | [x | _]]) do
    [x | stack]
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
