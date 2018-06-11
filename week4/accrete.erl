-module(accrete).
-export([start/4]).

start(Fx, N, A, B) ->
	CoreList=create(Fx, N, N, A, B, []),	%创建进程
	tellEveryOne(CoreList, CoreList).	%将进程列表告诉每一个进程

create(_, 0, _, _, _, L) ->
	L;
create(Fx, M, N, A, B, L) ->
	Pid=spawn(fun() -> coreTask(Fx, M, N, A, B, 2, 1) end),
	create(Fx, M-1, N, A, B, [Pid|L]).		%创建用于计算的进程列表

tellEveryOne([], _) ->
	ok;
tellEveryOne([H|T], L) ->
	H ! {wholeList, L},
	tellEveryOne(T, L).

getArea(Fx, M, N, A, B) ->
	Width=(B-A)/N,
	0.5*(Fx(A+Width*(M-1))+Fx(A+Width*M))*Width.

coalesce(_, N, _, LocalArea, _, N) ->		%迭代到头了
	io:format("the total area is: ~p~n", [LocalArea]);
coalesce(L, N, M, LocalArea, Divisor, CoreDifference) ->
	if 
		(M-1) rem Divisor =:= 0 -> 	%该进程应当接收
			receive
				{giveYou, Id, Area}	->
					if
						Id-M =:= CoreDifference ->
							io:format("block~p, union with block ~p~n", [M-1, Id-1]),
							TotalArea=LocalArea+Area,
							coalesce(L, N, M, TotalArea, Divisor*2, CoreDifference*2); %倍增，迭代
						true ->
							io:format("error~n")
					end
			end;
		true ->			%该进程应当发送
			Pid=lists:nth(M-CoreDifference, L),
			Pid ! {giveYou, M, LocalArea}	%向接收进程发送，之后不再活跃
	end.

coreTask(Fx, M, N, A, B, Divisor, CoreDifference) ->	%初次迭代，需要进行计算		
	LocalArea=getArea(Fx, M, N, A, B),
	io:format("block~p, this is local area:~p~n", [M-1, LocalArea]),
	receive				%等到中控进程发来所有进程列表后继续
		{wholeList, L} ->
			if 
				(M-1) rem Divisor =:= 0 -> 	%该进程应当接收
					receive
						{giveYou, Id, Area}	->
							io:format("this is area:~p~n", [Area]),
							if
								Id-M =:= CoreDifference ->
									io:format("block~p, union with block ~p~n", [M-1, Id-1]),
									TotalArea=LocalArea+Area,
									coalesce(L, N, M, TotalArea, Divisor*2, CoreDifference*2); %倍增，迭代
								true ->
									io:format("error~n")
							end
					end;
				true ->			%该进程应当发送
					Pid=lists:nth(M-CoreDifference, L),
					Pid ! {giveYou, M, LocalArea}	%向接收进程发送，之后不再活跃
			end
	end.			