-module(my).
-export([main/0]).

main() ->
	{_, NL}=io:fread("","~d"),
	N=lists:nth(1, NL),
	A=readList(N, []),
	print(littleWave(A, N, 1)).

print([])->
	io:format("~n"),ok;
print([H|T])->
	io:format("~p ",[H]),
	print(T).

littleWave(A, 1, _) ->
	A;
littleWave(A, N, CoreDifference) ->
	NewA=dolittleWave([], A, CoreDifference),
%	io:format("onced:~p...", [CoreDifference]),	print(NewA),
	littleWave(NewA, N div 2, CoreDifference*2).

delete(Position, List) ->
	L1=lists:sublist(List, Position-1),
	L2=lists:nthtail(Position, List),
	L1++L2.

dolittleWave(NA, A, 0) ->
	NA++A;
dolittleWave(NA, A, CoreDifference) ->
	H1=lists:nth(1, A),
	H2=lists:nth(CoreDifference+1, A),
%	io:format("H1:~p, H2:~p~n", [H1, H2]),
	P=(H1+H2) div 2,	
	Q=H1-P,
%	io:format("before delete:"),print(A),
	An=delete(1, A),
	Am=delete(CoreDifference, An),
%	io:format("deleted:"),	print(Am),
	NewA=NA++[P, Q],
%	io:format("solved:"),print(NewA),
	dolittleWave(NewA, Am, CoreDifference-1).	

readList(0, L) ->
	lists:reverse(L);
readList(N, L) ->
	{_, TmpList}=io:fread("", "~d"),
	readList(N-1, [lists:nth(1, TmpList)|L]).