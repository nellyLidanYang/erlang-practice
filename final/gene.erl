-module(gene).
-compile([export_all]).

start(N, K, L, Core) ->%N为序列长度，K为复制的份数，L为切分的每段基因序列平均长度，Core为核数
	%生成序列
	Sequence=genSequence(N, []),
	io:format("sequence:~p~n", [Sequence]),
	%shot gun
	Snippers=lists:sort(cutOff(Sequence, K, L, N, [])),
	%io:format("snipper:~p~n",[Snippers]),
	%分发任务
	register(monitor, spawn(fun() -> monitorTask(0, Core, [], length(Sequence)) end)),
	handOutTask(Snippers, trunc(length(Snippers)/Core), Core).

getTheResult([], Result) ->
	Result;
getTheResult([H|T], Result)->	
	L1=length(Result),
	L2=length(H),
	if
		L1 < L2 ->
			getTheResult(T, H);
		true ->
			getTheResult(T, Result)
	end.
monitorTask(Core, Core, List, LenS)->
	NewList=cleanSnippers(List, 1, 2, length(List)+1),
	Result=getTheResult(merge(NewList), []),%取最长那个作为结果
	io:format("final:~p~n", [Result]),
	io:format("ratio:~p~n", [length(Result)/LenS]);
monitorTask(Count, Core, List, LenS)->
	receive
		{Local} ->
			monitorTask(Count+1, Core, lists:append(List, Local), LenS);
		true ->
			io:format("error~n")
	end.
	
handOutTask(Slist, _, 1)->
	%最后一个全分配
	spawn(fun() -> coreTask(Slist) end);	
handOutTask(Slist, Len, Core)->
	{Head, Tail}=lists:split(Len, Slist),
	spawn(fun() -> coreTask(Head) end),
	handOutTask(Tail, Len, Core-1).

	
cleanSnippers(L, Len, _, Len)->%ij循环都结束
	%将[e]都删掉
	lists:filter(fun(X)->
		if
			X=:=[e]->false;
			true->true
		end end , L);
cleanSnippers(L, IA, Len, Len)->%j循环结束
	cleanSnippers(L, IA+1, 1, Len);
cleanSnippers(L, IA, IB, Len)->
	%io:format("L:~p~n", [L]),
	if
		IA=:=IB ->
			cleanSnippers(L, IA, IB+1, Len);
		true ->
			A=lists:nth(IA, L),
			B=lists:nth(IB, L),
			if
				A==[e] ->%IA所指的这个片段已经被删掉了,i++
					cleanSnippers(L, IA+1, 1, Len);
				B==[e] ->%IB所指的这个片段已经被删掉了,j++
					cleanSnippers(L, IA, IB+1, Len);
				true ->
					Index=string:str(lists:concat(A), lists:concat(B)),
					if
						Index =:= 0 ->%不包含
							cleanSnippers(L, IA, IB+1, Len);
						true ->%包含,将IB所指的元素变成[e](error)
							{Head, [_|Tail]}=lists:split(IB-1, L),
							cleanSnippers(lists:append([Head, [[e]], Tail]), IA, IB+1, Len)
					end
			end
	end.

overlap(_, _, 0)->%整个L2都是L1的后缀
	0;
overlap(L1, L2, Len)->	
	Head=lists:sublist(L2, Len),
	Cond=lists:suffix(Head, L1),%判断L2的长为Len的头是不是L1的后缀
	if
		Cond =:= false ->%不是，去掉后面一个再比对
			overlap(L1, L2, Len-1);
		true ->%是的
			Len
	end.

findMaxOverlap(_, Len, _, MaxClass, Len)->%ij循环都结束
	MaxClass;
findMaxOverlap(L, IA, Len, MaxClass, Len)->%j循环结束
	findMaxOverlap(L, IA+1, 1, MaxClass, Len);
findMaxOverlap(L, IA, IB, MaxClass, Len)->
	if
		IA =:= IB ->
			findMaxOverlap(L, IA, IB+1, MaxClass, Len);
		true ->
			OverLap=overlap(lists:nth(IA, L), lists:nth(IB, L), length(lists:nth(IB, L))),%得到IA所指串与IB所指串重叠的长度，IA在IB之前	
			{_, _, OL}=MaxClass,%之前的最大值
			if
				OverLap > OL ->%更新当前最大值
					findMaxOverlap(L, IA, IB+1, {IA, IB, OverLap}, Len);
				true->
					findMaxOverlap(L, IA, IB+1, MaxClass, Len)
			end
	end.
	
merge(List)->
	{Index1, Index2, OverLap}=findMaxOverlap(List, 1, 2, {0, 0, 0}, length(List)+1),
	if	
		OverLap =:= 0 ->%合并完毕
			List;
		true ->
			%New为合并得到的一个新串
			New=lists:append(lists:nth(Index1, List), lists:nthtail(OverLap, lists:nth(Index2, List))),
			%去掉Index1、Index2所指向的两个串，生成一个新的串list
			if
				Index1 < Index2 ->
					{A, [_|B]}=lists:split(Index1-1, List),
					{C, [_|D]}=lists:split(Index2-Index1-1, B),
					NewList=lists:append([A, C, D]),
					merge(lists:append(NewList, [New]));
				true ->
					{A, [_|B]}=lists:split(Index2-1, List),
					{C, [_|D]}=lists:split(Index1-Index2-1, B),
					NewList=lists:append([A, C, D]),
					merge(lists:append(NewList, [New]))
			end
	end.
	
coreTask(List)->
	%io:format("~p~n", [List]),
	%洗掉被包含的短串
	CleanList=cleanSnippers(List, 1, 2, length(List)+1),
	%io:format("cleaned:~p~n", [CleanList]),
	%将短串们合并
	LocalMerge=merge(CleanList),
	%io:format("local merge:~p~n", [LocalMerge]),
	%将合并结果发给中控进程
	monitor ! {LocalMerge}.

%随机生成长度为N的基因序列
genSequence(0, List)->
	List;
genSequence(N, List)->
	X=random:uniform(4),
	if
		X=:=1 ->%A
			genSequence(N-1, lists:append(List, [a]));
		X=:=2 ->%C
			genSequence(N-1, lists:append(List, [c]));
		X=:=3 ->%G
			genSequence(N-1, lists:append(List, [g]));
		true->%T
			genSequence(N-1, lists:append(List, [t]))
	end.

cutOff(_, 0, _, _, List)->
	%io:format("~p~n", [List]),
	List;
cutOff(S, K, L, N, List) ->%把片段切碎，所有片段存在一个list里面，注意S是字符串
	CutLen=getCutLength(trunc(N/L), L, N, []),
	Local=littleCutOff(CutLen, S, []),
	%Local=littleCutOff(S, trunc(N/L), L, []),
	cutOff(S, K-1, L, N, lists:append(Local, List)).

littleCutOff([H|T], S, List) when T =/= [] ->	
	{Head, Tail}=lists:split(H, S),
	littleCutOff(T, Tail, lists:append(List, [Head]));
littleCutOff(_, S, List) ->
	lists:append(List, [S]).
	
%得到一个随机数list，是每块碎片的长度，和为N
flat(Over, List)->
	Length=length(List),
	{Head, [Last]}=lists:split(Length-1, List),
	if
		Last > Over->
			lists:append(Head, [Last-Over]);%flat(Over, List);
		Last =:= Over ->
			Head;
		true ->
			flat(Over-Last, Head)
	end.			
getCutLength(0, _, N, List)->
	Sum=lists:sum(List),
	%io:format("~p~n", [List]),
	%io:format("~p~n", [Sum]);
	if
		Sum > N ->
			flat(Sum-N, List);
		Sum =:= N ->
			List;
		true ->
			lists:append(List, [N-Sum])
	end;
getCutLength(Time, L, N, List)->
	X=random:uniform(2*L),
	getCutLength(Time-1, L, N, List++[X]).