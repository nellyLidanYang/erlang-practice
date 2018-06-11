-module(psrs).
-compile([export_all]).

start() ->
	io:format("how many numbers?~n"),
	{_, NL}=io:fread("", "~d"),
	N=lists:nth(1, NL),
	io:format("input ~p number:~n", [N]),
	Data=readList(N, []),
	io:format("how many parts?~n"),
	{_, NC}=io:fread("", "~d"),
	P=lists:nth(1, NC),
	%print(Data).
	register(monitor, spawn(fun() -> monitorTask(P) end)),%中控进程
	handout(P, 0, Data, N/P).

handout(P, P, _, _) ->
	ok;
handout(P, Id, Data, Len) ->
	register(nameProcess(Id), spawn(fun()-> coreTask(lists:sublist(Data, trunc(1+Id*Len), trunc(Len)), Id, P, Len) end)),
	handout(P, Id+1, Data, Len).

nameProcess(Id) ->
	Name="process"++integer_to_list(Id),
	list_to_atom(Name).

%处理数据的进程工作
coreTask(Frame, Id, P, Len)->
	SortedFrame=quicksort(Frame),
	Sample=sampling(SortedFrame, P, trunc(Len/P), []),
	monitor ! {Id, Sample},%将样本发送给中控进程
	%接收P-1个主元
	receive
		{monitor, MainPivots} ->
			%io:format("#####~n"),
			MainPivots,
			littlehandout(SortedFrame, MainPivots, 0, Id),
			%io:format("$$$$$~p~n",[Id]),
			NewList=waitPart([], P, 0, Id),
			%io:format("iam ~p", [Id]),print(NewList),
			Sorted=quicksort(NewList),
			monitor ! {Id, Sorted};
		true ->
			io:format("error~n")
	end.
	

waitPart(List, P, P, _) ->
	List;
waitPart(List, P, Time, Id) ->
	receive
		{FId, PartList} ->
			io:format("im ~p %%%%%get ~p~n", [Id, FId]),
			waitPart(List++PartList, P, Time+1, Id);
		true ->
			io:format("error~n")
	end.

littlehandout(Frame, [], Parts, Id) ->
	Process=nameProcess(Parts),
	%io:format("&&&&&&&&Id:~p to ~p~n", [Id, Process]),print(Frame),
	Process ! {Id, Frame};
littlehandout(Frame, [H|T], Parts, Id) ->
	L=[X || X<-Frame, X =< H],
	Process=nameProcess(Parts),
	%io:format("&&&&&&&&Id:~p to ~p~n", [Id, Process]),print(L),
	Process ! {Id, L},
	Len=length(L),
	LeftFrame=lists:nthtail(Len, Frame),
	littlehandout(LeftFrame, T, Parts+1, Id).


%中控进程工作
monitorTask(P) ->
	List=waitSample([], 0, P),
	Sorted=quicksort(List),
	%io:format("sample:"),print(Sorted),
	Len=trunc(length(Sorted)/P),
	%io:format("LEn:~p~n", [Len]),
	MainPivots=sampling2(Sorted, P-1, Len, []),%跳过1，每隔p取一个做主元，共p-1个
	%io:format("mian pivots:"),print(MainPivots),
	broadcast(MainPivots, P),%向所有工作进程广播
	waitSorted(dict:new(), P, 0).

waitSorted(Dict, P, Count)->
	if
		Count ==  P ->
			io:format("endpoint~n"),
			Result=getlist(Dict, P, 0, []),
			print(Result);
		true ->
			receive
				{Id, LocalList} ->
					%io:format("iam monitor, get msg form ~p~n", [Id]),print(LocalList),
					NewDict=dict:append(Id, LocalList, Dict),
					waitSorted(NewDict, P, Count+1);
				true ->
					io:format("error~n")
			end
	end.

%将字典里的各段排序结果按id合并成一个list
getlist(_, Total, Total, List) ->
	List;
getlist(Dict, Total, Now, List) ->
	LocalList=dict:fetch(Now, Dict),
	NewList=List++lists:nth(1, LocalList),%字典里的value被包在一个list里
	%print(NewList),
	getlist(Dict, Total, Now+1, NewList).
	
	
waitSample(List, P, P) ->
	List;
waitSample(List, Time, P) ->
	receive
		{_, SamList} ->
			waitSample(List++SamList, Time+1, P);
		true ->
			io:format("error~n")
	end.

broadcast(List, P) when P > 0 ->
	%io:format(nameProcess(P-1)),
	nameProcess(P-1) ! {monitor, List},
	broadcast(List, P-1);
broadcast(_, _) ->
	ok.

sampling(_, 0, _, List) ->
	List;
sampling(Data, P, Len, List) ->
	S=lists:nth(trunc(1+Len*(P-1)), Data),
	sampling(Data, P-1, Len, [S|List]).

sampling2(_, 0, _, List) ->
	List;
sampling2(Data, Time, Len, List) ->%取主元
	S=lists:nth(1+trunc(Time*Len), Data),
	sampling2(Data, Time-1, Len, [S|List]).

quicksort([]) ->
	[];
quicksort([Pivot|T])->
	quicksort([X || X <- T, X =< Pivot]) ++ [Pivot] ++ quicksort([X || X<-T, X>Pivot]).

readList(0, L) ->
	lists:reverse(L);
readList(N, L) ->
	{_, TmpList}=io:fread("", "~d"),
	readList(N-1, [lists:nth(1, TmpList)|L]).

print([]) ->
	ok;
print([H|T]) ->
	io:format("~p~n",[H]),
	print(T).