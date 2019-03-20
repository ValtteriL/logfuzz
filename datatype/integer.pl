:- module(integer, [integer/1]).

% integers
fuzz_integer(-1).
fuzz_integer(0).
fuzz_integer(-9999).
fuzz_integer(9999).