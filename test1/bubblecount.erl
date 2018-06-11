-module(bubble).
-export([main/0]).

main() ->
	{_, NL}=io:fread("","~d"),
	N=lists:nth(1, NL),
	L=readList(N, []),
	io:format("~p~n", [bubbleSortTime(L, 0)]).

bubble(M, [], Time) -> Time;
bubble(M, [H|T], Time)->
	if
		M>H ->
			bubble(M, T, Time+1);
		true ->
			bubble(M, T, Time)
	end.

bubbleSortTime([], Time) -> Time;
bubbleSortTime([H|T], Time) ->
	bubbleSortTime(T, bubble(H, T, 0)+Time).

readList(0, L) ->
	lists:reverse(L);
readList(N, L) ->
	{_, TmpList}=io:fread("", "~d"),
	readList(N-1, [lists:nth(1, TmpList)|L]).
