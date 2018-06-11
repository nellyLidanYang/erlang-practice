-module(bubble).
-export([main/0]).

main() ->
	{_, NL}=io:fread("","~d"),
	N=lists:nth(1, NL),
	L=readList(N, []),
	io:format("~p~n", [bubbleSortTime(N, L, 0)]).

bubbleSortTime(1, _, Time) -> Time;
bubbleSortTime(N, L, Time) ->
	{LocalTime, NewL}=bubble(N-1, L, L, 1, 0),
	NewList=lists:sublist(NewL, N-1),
	bubbleSortTime(N-1, NewList, Time+LocalTime).%每次都从头开始

swap(H1, H2, T, L, I) ->
	if
		I=:= 1 ->
			[H2]++[H1|T];
		true ->
			lists:sublist(L, I-1)++[H2, H1|T]
	end.

bubble(0, L, _, _, Time)->
	{Time, L};
bubble(N, L, [H1, H2|T], I, Time) ->
	if
		H1 > H2 ->
			NewL=swap(H1, H2, T,  L, I),
			bubble(N-1, NewL, [H1|T], I+1, Time+1);
		true ->
			bubble(N-1, L, [H2|T], I+1, Time)
	end.

readList(0, L) ->
	lists:reverse(L);
readList(N, L) ->
	{_, TmpList}=io:fread("", "~d"),
	readList(N-1, [lists:nth(1, TmpList)|L]).