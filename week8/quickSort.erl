-module(quickSort).
-export([start/0]).

start()->
	io:format("how many numbers?~n"),
	{_, NL}=io:fread("", "~d"),
	N=lists:nth(1, NL),
	io:format("input ~p number:~n", [N]),
	Data=readList(N, []),
	io:format("how many layers?~n"),
	{_, NC}=io:fread("", "~d"),
	M=lists:nth(1, NC),
	%print(Data),
	register(monitor, spawn(fun() -> wait(dict:new(), M, 0) end)),%�пؽ��̣����Ի��ܽ��
	spawn(fun() -> coretask(Data, 0, M) end).

print([])->
	io:format("~n"),ok;
print([H|T])->
	io:format("~p,",[H]),
	print(T).

coretask(Data, Id, M) ->
	Condition1= length(Data)<2,
	Condition2= M=:=0,
	Condition=Condition1 or Condition2,
	if
		Condition =:= true ->
			%io:format("handle small scale~n"),
			Sorted=quicksort(Data),
			%io:format("iam ~p, sorted:~n", [Id]),print(Sorted),
			monitor ! 	{Id, Sorted};%����Ϣ���пؽ���
		Condition =:= false ->
			%io:format("iam ~p, split~n", [Id]),
			[H|T]=Data,%T����Ϊ�գ���Ϊ��Data��Ԫ�ظ���Ϊ1��ʱ������˵�һ��brunch
			Left=[X|| X<-T, X<H],
			%io:format("id:~p, left:", [Id]),print(Left),
			Right=[X|| X<-T, X>=H],
			%io:format("id:~p, right:", [Id]),print(Right),
			spawn(fun()->coretask(Right, Id+trunc(math:pow(2, M-1)), M-1) end),
			coretask(Left++[H], Id, M-1)
	end.

quicksort([])->
	[];
quicksort([Pivot|T])->
	quicksort([X || X <- T, X =< Pivot]) ++ [Pivot] ++ quicksort([X || X<-T, X>Pivot]).

wait(Dict, M, Count)->
	Total=trunc(math:pow(2, M)),
%	io:format("count: ~p, total: ~p ~n", [Count, Total]),
	if
		Count == Total ->
			io:format("endpoint~n"),
			Result=getlist(Dict, trunc(math:pow(2, M)), 0, []),
			print(Result);
		true ->
			receive
				{Id, LocalList} ->
					%io:format("iam monitor, get msg form ~p~n", [Id]),print(LocalList),
					NewDict=dict:append(Id, LocalList, Dict),
					wait(NewDict, M, Count+1);
				true ->
					io:format("error~n")
			end
	end.

%���ֵ���ĸ�����������id�ϲ���һ��list
getlist(_, Total, Total, List) ->
	List;
getlist(Dict, Total, Now, List) ->
	LocalList=dict:fetch(Now, Dict),
	NewList=List++lists:nth(1, LocalList),%�ֵ����value������һ��list��
	%print(NewList),
	getlist(Dict, Total, Now+1, NewList).

readList(0, L) ->
	lists:reverse(L);
readList(N, L) ->
	{_, TmpList}=io:fread("", "~d"),
	readList(N-1, [lists:nth(1, TmpList)|L]).