Definitions.

ID         = [a-zA-Z][a-zA-Z0-9_-]*
INT        = [0-9]+
OPERATORS  = [-+/*]
% The last glyph that looks like a hyphen is an Ogham space mark.
WHITESPACE = [\x00-\x20\s ]+

Rules.

{WHITESPACE} : skip_token.
{INT}        : {token, {int, TokenLine, list_to_integer(TokenChars)}}.
\:           : {token, {startdef, TokenLine}}.
\;           : {token, {enddef, TokenLine}}.
{ID}         : {token, {id, TokenLine, TokenChars}}.
{OPERATORS}  : {token, {op, TokenLine, TokenChars}}.

Erlang code.
