-module(concatList).
-compile([export_all]).

reverse(L) -> reverse(L, []).
reverse([], R) -> R;
reverse([H|T], R) -> reverse(T, [H|R]).

linkStep(L, []) -> L;
linkStep(L1, [H|T]) -> linkStep([H|L1], T).

link(L1, L2) ->
	reverse(linkStep(reverse(L1), L2)).