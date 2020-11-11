Nonterminals expr.
Terminals plus minus star slash dup drop swap over int.
Rootsymbol expr.

expr -> .

Erlang code.

extract_token({_Token, _Line, Value}) -> Value.
