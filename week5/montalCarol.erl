-module(montalCarol).
-compile([export_all]).

start(PointNumber, CoreNumber) ->
	CoreList=create(PointNumber, CoreNumber, CoreNumber, []),	%创建进程
	tellEveryOne(CoreList, CoreList).	%将进程列表告诉每一个进程

create(_, 0, _, L) ->
	L;
create(PN, CN, CoreNumber, L) ->
	Pid=spawn(fun() -> coreTask(PN, CN, CoreNumber, 2, 1) end),
	create(PN, CN-1, CoreNumber, [Pid|L]).		%创建进程列表

tellEveryOne([], _) ->
	ok;
tellEveryOne([H|T], L) ->
	H ! {wholeList, L},
	tellEveryOne(T, L).

coalesce(L, CN, CoreNumber, LocalTarget, Divisor, CoreDifference, PointNumber) when CoreDifference =< CoreNumber ->
	if 
		(CN-1) rem Divisor =:= 0 -> 	%该进程应当接收
			if
				CN-1+CoreDifference < CoreNumber ->	%这个应当接收的进程有对应给予进程，不轮空
					receive
						{giveYou, Id, Target}	->
								io:format("core~p, union with core ~p~n", [CN-1, Id-1]),
								coalesce(L, CN, CoreNumber, LocalTarget+Target, Divisor*2, CoreDifference*2, PointNumber) %倍增，迭代
					end;
				true ->	%这个应当接收的进程无对应给予进程，轮空
					coalesce(L, CN, CoreNumber, LocalTarget, Divisor*2, CoreDifference*2, PointNumber)
			end;
		true ->			%该进程应当发送
			Pid=lists:nth(CN-CoreDifference, L),
			Pid ! {giveYou, CN, LocalTarget}	%向接收进程发送，之后不再活跃
	end;
coalesce(_, _, _, LocalTarget, _, _, PointNumber)->
	io:format("total:~p~n", [LocalTarget]),
	io:format("Pi is about:~p~n", [4*LocalTarget/PointNumber]).

%随机生成点并累加落在圆内的数目
getTarget(0, Target) ->
	Target;
getTarget(Times, Target) ->
	random:seed(erlang:phash2([node()]), erlang:monotonic_time(), erlang:unique_integer()),%给每个进程分配不同的种子以保证生成的随机数不同
	X=random:uniform(),			%生成随机数
	Y=random:uniform(),
	if
		((X-1)*(X-1)+(Y-1)*(Y-1)) =< 1 ->	%该随机点落在圆内
			getTarget(Times-1, Target+1);
		true ->
			getTarget(Times-1, Target)
	end.

coreTask(PN, CN, CoreNumber, Divisor, CoreDifference) ->	%初次迭代，需要进行计算		
	LocalTarget=getTarget(PN div CoreNumber, 0),
	io:format("core~p, local target:~p~n", [CN-1, LocalTarget]),
	receive				%等到中控进程发来所有进程列表后继续
		{wholeList, L} ->
			if 
				(CN-1) rem Divisor =:= 0 -> 	%该进程应当接收
					if
						CN-1+CoreDifference < CoreNumber ->	%这个应当接收的进程有对应给予进程，不轮空
							receive
								{giveYou, Id, Target}	->
									io:format("~p get msg from core~p, target:~p~n", [CN-1, Id-1, Target]),
									io:format("core~p, union with core ~p~n", [CN-1, Id-1]),
									coalesce(L, CN, CoreNumber, LocalTarget+Target, Divisor*2, CoreDifference*2, PN)%倍增，迭代
				
							end;
						true ->	
							io:format("im ~p~n", [CN-1]),			%这个应当接收的进程无对应进程，轮空
							coalesce(L, CN, CoreNumber, LocalTarget, Divisor*2, CoreDifference*2, PN)
					end;
				true ->	%该进程应当发送
					io:format("sending:~p to ~p~n", [CN-1, CN-CoreDifference]),
					Pid=lists:nth(CN-CoreDifference, L),
					Pid ! {giveYou, CN, LocalTarget}	%向接收进程发送，之后不再活跃
			end
	end.			