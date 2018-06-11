-module(gene).
-compile([export_all]).

start(N, K, L, Core) ->%NΪ���г��ȣ�KΪ���Ƶķ�����LΪ�зֵ�ÿ�λ�������ƽ�����ȣ�CoreΪ����
	%��������
	Sequence=genSequence(N, []),
	io:format("sequence:~p~n", [Sequence]),
	%shot gun
	Snippers=lists:sort(cutOff(Sequence, K, L, N, [])),
	%io:format("snipper:~p~n",[Snippers]),
	%�ַ�����
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
	Result=getTheResult(merge(NewList), []),%ȡ��Ǹ���Ϊ���
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
	%���һ��ȫ����
	spawn(fun() -> coreTask(Slist) end);	
handOutTask(Slist, Len, Core)->
	{Head, Tail}=lists:split(Len, Slist),
	spawn(fun() -> coreTask(Head) end),
	handOutTask(Tail, Len, Core-1).

	
cleanSnippers(L, Len, _, Len)->%ijѭ��������
	%��[e]��ɾ��
	lists:filter(fun(X)->
		if
			X=:=[e]->false;
			true->true
		end end , L);
cleanSnippers(L, IA, Len, Len)->%jѭ������
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
				A==[e] ->%IA��ָ�����Ƭ���Ѿ���ɾ����,i++
					cleanSnippers(L, IA+1, 1, Len);
				B==[e] ->%IB��ָ�����Ƭ���Ѿ���ɾ����,j++
					cleanSnippers(L, IA, IB+1, Len);
				true ->
					Index=string:str(lists:concat(A), lists:concat(B)),
					if
						Index =:= 0 ->%������
							cleanSnippers(L, IA, IB+1, Len);
						true ->%����,��IB��ָ��Ԫ�ر��[e](error)
							{Head, [_|Tail]}=lists:split(IB-1, L),
							cleanSnippers(lists:append([Head, [[e]], Tail]), IA, IB+1, Len)
					end
			end
	end.

overlap(_, _, 0)->%����L2����L1�ĺ�׺
	0;
overlap(L1, L2, Len)->	
	Head=lists:sublist(L2, Len),
	Cond=lists:suffix(Head, L1),%�ж�L2�ĳ�ΪLen��ͷ�ǲ���L1�ĺ�׺
	if
		Cond =:= false ->%���ǣ�ȥ������һ���ٱȶ�
			overlap(L1, L2, Len-1);
		true ->%�ǵ�
			Len
	end.

findMaxOverlap(_, Len, _, MaxClass, Len)->%ijѭ��������
	MaxClass;
findMaxOverlap(L, IA, Len, MaxClass, Len)->%jѭ������
	findMaxOverlap(L, IA+1, 1, MaxClass, Len);
findMaxOverlap(L, IA, IB, MaxClass, Len)->
	if
		IA =:= IB ->
			findMaxOverlap(L, IA, IB+1, MaxClass, Len);
		true ->
			OverLap=overlap(lists:nth(IA, L), lists:nth(IB, L), length(lists:nth(IB, L))),%�õ�IA��ָ����IB��ָ���ص��ĳ��ȣ�IA��IB֮ǰ	
			{_, _, OL}=MaxClass,%֮ǰ�����ֵ
			if
				OverLap > OL ->%���µ�ǰ���ֵ
					findMaxOverlap(L, IA, IB+1, {IA, IB, OverLap}, Len);
				true->
					findMaxOverlap(L, IA, IB+1, MaxClass, Len)
			end
	end.
	
merge(List)->
	{Index1, Index2, OverLap}=findMaxOverlap(List, 1, 2, {0, 0, 0}, length(List)+1),
	if	
		OverLap =:= 0 ->%�ϲ����
			List;
		true ->
			%NewΪ�ϲ��õ���һ���´�
			New=lists:append(lists:nth(Index1, List), lists:nthtail(OverLap, lists:nth(Index2, List))),
			%ȥ��Index1��Index2��ָ���������������һ���µĴ�list
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
	%ϴ���������Ķ̴�
	CleanList=cleanSnippers(List, 1, 2, length(List)+1),
	%io:format("cleaned:~p~n", [CleanList]),
	%���̴��Ǻϲ�
	LocalMerge=merge(CleanList),
	%io:format("local merge:~p~n", [LocalMerge]),
	%���ϲ���������пؽ���
	monitor ! {LocalMerge}.

%������ɳ���ΪN�Ļ�������
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
cutOff(S, K, L, N, List) ->%��Ƭ�����飬����Ƭ�δ���һ��list���棬ע��S���ַ���
	CutLen=getCutLength(trunc(N/L), L, N, []),
	Local=littleCutOff(CutLen, S, []),
	%Local=littleCutOff(S, trunc(N/L), L, []),
	cutOff(S, K-1, L, N, lists:append(Local, List)).

littleCutOff([H|T], S, List) when T =/= [] ->	
	{Head, Tail}=lists:split(H, S),
	littleCutOff(T, Tail, lists:append(List, [Head]));
littleCutOff(_, S, List) ->
	lists:append(List, [S]).
	
%�õ�һ�������list����ÿ����Ƭ�ĳ��ȣ���ΪN
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