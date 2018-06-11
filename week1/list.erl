-module(list).
-compile([export_all]).

create(X) -> 
	if
		X =:=1 -> [1];
		X =/=1 -> create(X-1)++[X]
	end.

reverse_create(X) -> 
	reverse(create(X)).

reverse(L) -> reverse(L,[]).
reverse([],R) -> R;
reverse([H|T],R) -> reverse(T,[H|R]).

create1(X) -> create(X, []).
create1(1, L) -> [1|L];
create1(X, L) -> create1(X-1, [X|L]).