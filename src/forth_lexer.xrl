Definitions.

INT        = [0-9]+
WHITESPACE = [\s\t\n\r]

Rules.

\+            : {token, {plus,  TokenLine}}.
\-            : {token, {minus, TokenLine}}.
\*            : {token, {star,  TokenLine}}.
\/            : {token, {slash, TokenLine}}.
DUP           : {token, {dup,   TokenLine}}.
DROP          : {token, {drop,  TokenLine}}.
SWAP          : {token, {swap,  TokenLine}}.
OVER          : {token, {over,  TokenLine}}.
{INT}         : {token, {int,   TokenLine, list_to_integer(TokenChars)}}.
{WHITESPACE}+ : skip_token.

Erlang code.
