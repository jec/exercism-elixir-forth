defmodule Forth.Tokenizer do
  @moduledoc """
  Tokenizes a simplified Forth source

  States:
  * none -- not buffering anything
  * int -- buffering an integer
  * id -- buffering an identifier
  """

  defstruct [state: :none, buf: ""]

  @type t :: %Forth.Tokenizer{state: state(), buf: String.t()}

  @type state :: :none | :int | :id

  @type token_type :: :op, :int, :id, :startdef, :enddef, :eof

  @doc """
  Tokenizes a Forth source string and returns a tuple with the token type,
  token value, and remaining string
  """
  @spec eval(t(), String.t()) :: {token_type(), any, String.t()}
  def eval(string, tkz \\ %Forth.Tokenizer{})

  ### State: none ###

  # Input: end-of-string
  # Output: return :eof
  def eval(<<>>, %Forth.Tokenizer{state: :none}) do
    {:eof, nil, ""}
  end

  # Input: digit
  # Output: create buffer with digit as initial value
  # Next state: int
  def eval(<<ch::utf8, rest::binary>>, %Forth.Tokenizer{state: :none}) when ?0 <= ch and ch <= ?9 do
    eval(rest, %Forth.Tokenizer{state: :int, buf: <<ch>>})
  end

  # Input: non-printing char or space
  # Output: no-op
  # Next state: same state (none)
  def eval(<<ch::utf8, rest::binary>>, tkz = %Forth.Tokenizer{state: :none}) when ch <= 32 or ch == ?  do
    eval(rest, tkz)
  end

  # Input: binary operator
  # Output: return the operator
  def eval(<<ch::utf8, rest::binary>>, %Forth.Tokenizer{state: :none}) when ch == ?+ or ch == ?- or ch == ?* or ch == ?/ do
    {:op, ch, rest}
  end

  # Input: start-of-definition character (:)
  # Output: return the operator
  def eval(<<ch::utf8, rest::binary>>, %Forth.Tokenizer{state: :none}) when ch == ?: do
    {:startdef, nil, rest}
  end

  # Input: end-of-definition character (;)
  # Output: return the operator
  def eval(<<ch::utf8, rest::binary>>, %Forth.Tokenizer{state: :none}) when ch == ?; do
    {:enddef, nil, rest}
  end

  # Input: other character
  # Output: create buffer with character as initial value
  # Next state: identifier
  def eval(<<ch::utf8, rest::binary>>, %Forth.Tokenizer{state: :none}) do
    eval(rest, %Forth.Tokenizer{state: :id, buf: <<ch::utf8>>})
  end

  ### State: int ###

  # Input: end-of-string
  # Output: return the buffered integer
  def eval(<<>>, %Forth.Tokenizer{state: :int, buf: buf}) do
    {:int, String.to_integer(buf), ""}
  end

  # Input: digit
  # Output: append digit to buffer
  # Next state: same state (int)
  def eval(<<ch::utf8, rest::binary>>, %Forth.Tokenizer{state: :int, buf: buf}) when ?0 <= ch and ch <= ?9 do
    eval(rest, %Forth.Tokenizer{state: :int, buf: buf <> <<ch>>})
  end

  # Input: non-printing char or space
  # Output: return buffered integer
  def eval(<<ch::utf8, rest::binary>>, %Forth.Tokenizer{state: :int, buf: buf}) when ch <= 32 or ch == ?  do
    {:int, String.to_integer(buf), rest}
  end

  ### State: id ###

  # Input: end-of-string
  # Output: return the buffered identifier
  def eval(<<>>, %Forth.Tokenizer{state: :id, buf: buf}) do
    {:id, buf, ""}
  end

  # Input: non-printing char or space
  # Output: return the buffered identifier
  def eval(<<ch::utf8, rest::binary>>, %Forth.Tokenizer{state: :id, buf: buf}) when ch <= 32 or ch == ?  do
    {:id, buf, rest}
  end

  # Input: other character
  # Output: append character to buffer
  # Next state: same state (id)
  def eval(<<ch::utf8, rest::binary>>, %Forth.Tokenizer{state: :id, buf: buf}) do
    eval(rest, %Forth.Tokenizer{state: :id, buf: buf <> <<ch::utf8>>})
  end
end
