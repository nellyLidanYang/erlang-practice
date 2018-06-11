-module(oddEvenSwap).
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
	
	%reshape，保证数字数目(N)是段数(P)的整倍数；N、P要是偶数
	if
		P rem 2 =:= 1 ->%P不是偶数
			NewP=P+1;
		true ->
			NewP=P
	end,
	if
		N rem NewP =/= 0 ->%N不是NewP的倍数
			%填充
			Max=lists:max(Data)+1,%无穷大
			NewN=((N rem NewP)+1)*NewP,
			Need=NewN-N,
			Fill=lists:duplicate(Need, Max),
			NewData=Data++Fill;%把缺的用无穷大补上
		true ->
			NewN=N,
			NewData=Data
	end,
	
	
	register(monitor, spawn(fun() -> wait(P, [], N) end)),%中控进程，用以汇总结果
	create(NewP, trunc(NewN/NewP), NewData, NewP).

create(0, _, _, _) ->
	ok;
create(P, Len, Data, Total) ->
	{L, F}=split(Data, Len, []),
	register(nameProcess(P), spawn(fun() -> doEven(P, Len, Total, L, Total) end)),
	create(P-1, Len, F, Total).

wait(0, List, N) ->
	io:format("sort result: ~p", [lists:sublist(List, N)]);
wait(P, List, N) ->
	receive
		{P, L} ->
			wait(P-1, L++List, N)
	end.

doOdd(Id, _, 0, Local, _) ->
	monitor ! {Id, Local};
doOdd(Id, Len, Time, Local, Total) ->
	Cond1=Id ==1,
	Cond2=Id ==Total,
	Cond=Cond1 or Cond2,
	if
		Cond =:= true ->%轮空
			doEven(Id, Len, Time-1, Local, Total);
		Cond =:= false ->
			if
				Id rem 2 =:= 0 ->%和下一个进程组成一对,保留较小的部分
					OtherID=nameProcess(Id+1),
					OtherID ! {nameProcess(Id), Local},
					receive
						{OtherID, Other} ->
							Sorted=quicksort(Local++Other),
							My=lists:sublist(Sorted, Len),
							doEven(Id, Len, Time-1, My, Total)
					end;
				Id rem 2 =:= 1 ->%和上一个进程组成一对,保留较大的部分
					OtherID=nameProcess(Id-1),
					OtherID ! {nameProcess(Id), Local},
					receive
						{OtherID, Other} ->
							Sorted=quicksort(Local++Other),
							My=lists:nthtail(Len, Sorted),
							doEven(Id, Len, Time-1, My, Total)
					end
			end
	end.

doEven(Id, _, 0, Local, _) ->
	monitor ! {Id, Local};
doEven(Id, Len, Time, Local, Total) ->
	if
		Id rem 2 =:= 1 ->%和下一个进程组成一对,保留较小的部分
			OtherID=nameProcess(Id+1),
			OtherID ! {nameProcess(Id), Local},
			receive
				{OtherID, Other} ->
					Sorted=quicksort(Local++Other),
					My=lists:sublist(Sorted, Len),
					doOdd(Id, Len, Time-1, My, Total)
			end;
		true ->%和上一个进程组成一对,保留较大的部分
			OtherID=nameProcess(Id-1),
			OtherID ! {nameProcess(Id), Local},
			receive
				{OtherID, Other} ->
					Sorted=quicksort(Local++Other),
					My=lists:nthtail(Len, Sorted),
					doOdd(Id, Len, Time-1, My, Total)
			end
	end.


nameProcess(Id) ->
	Name="process"++integer_to_list(Id),
	list_to_atom(Name).

quicksort([]) ->
	[];
quicksort([Pivot|T])->
	quicksort([X || X <- T, X =< Pivot]) ++ [Pivot] ++ quicksort([X || X<-T, X>Pivot]).

split(L, 0, F) ->
	{F, L};
split([H|T], N, F)->%将list前N项分出来切成两块
	split(T, N-1, [H|F]).

readList(0, L) ->
	L;
readList(N, L) ->
	{_, TmpList}=io:fread("", "~d"),
	readList(N-1, [lists:nth(1, TmpList)|L]).