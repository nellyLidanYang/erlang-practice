-module(my).
-export([main/0]).

main() ->
	{_, L1}=io:fread("","~d"),
	List1=reverse(readList(lists:nth(1, L1), [])),
	{_, L2}=io:fread("","~d"),
	List2=reverse(readList(lists:nth(1, L2), [])),
	List=reverse(cutCard1(lists:nth(1, L1), lists:nth(1, L2), List1, List2, [])),
	print(List).

print([])->
	ok;
print([H|T])->
	io:format("~p~n",[H]),
	print(T).

readList(0, L) ->
	L;
readList(N, L) ->
	{_, TmpList}=io:fread("", "~d"),
	readList(N-1, [lists:nth(1, TmpList)|L]).

cutCard1(N1 , 0, L1, _, L) ->
	reverse(L1)++L;
cutCard1(N1, N2, [H|T], L2, L) ->
	cutCard2(N1-1, N2, T, L2, [H|L]).

cutCard2(0, N2, _, L2, L) ->
	reverse(L2)++L;
cutCard2(N1, N2, L1, [H|T], L) ->
	cutCard1(N1, N2-1, L1, T, [H|L]).

reverse(L) -> reverse(L, []).
reverse([], R) -> R;
reverse([H|T], R) -> reverse(T, [H|R]).