-module(wordIndex).
-compile([export_all]).

start() ->
	io:format("please input file number:~n"),
	{_, NL}=io:fread("", "~d"),
	N=lists:nth(1, NL),
	NameList=readList(N, []),
%	printList(NameList),
	CoreList=create(N, N, NameList, []),		%创建进程
	tellEveryOne(CoreList, CoreList).	%将进程列表告诉每一个进程

readList(0, L) ->
	L;
readList(N, L) ->
	{_, TmpList}=io:fread("", "~s"),
	readList(N-1, [lists:nth(1, TmpList)|L]).

create(0, _, _, L) ->
	L;
create(N, Number, [H|T], L) ->
	Pid=spawn(fun() -> coreTask(N, Number, H, 2, 1) end),	%分配文件名
	create(N-1, Number, T, [Pid|L]).		%创建进程列表

tellEveryOne([], _) ->
	ok;
tellEveryOne([H|T], L) ->
	H ! {wholeList, L},
	tellEveryOne(T, L).

%处理一行内的字典
getThisLine(_, _, [], NowDict)->
	NowDict;
getThisLine(N, LineNumber, [H|T], NowDict)->
	Find=dict:find(H, NowDict),
	if
		Find =:= error ->	%不存在于该行的字典中
			NewDict=dict:store(H, [{N, LineNumber, 1}], NowDict); %一开始就存成包含tuple的list：文件号、行号、数目
		true ->
			NewDict=dict:update(H, fun(V) -> %将number增加一
					{FileN, LineN, Time}=lists:nth(1, V),
					NewTup={FileN, LineN, Time+1},
					[NewTup]  end, NowDict)
	end,
	getThisLine(N, LineNumber, T, NewDict).

%循环对文件的每一行进行处理
getIndex(_, _, eof, _, Dict) ->
	Dict;
getIndex(N, File, Line, LineNumber, Dict) ->
	LineList=string:tokens(Line," .,:;\"\n"),%按空格、逗号、句号、冒号、分号、引号将一行分割成一个list
	LocalDict=getThisLine(N, LineNumber, LineList, dict:new()),
	TotalDict=dict:merge(fun(K, V1, V2) -> V1++V2 end, LocalDict, Dict),
	getIndex(N, File, io:get_line(File, ''), LineNumber+1, TotalDict).

unconsult(List) ->
	{ok, S}=file:open("output.txt", write),
	lists:foreach(fun(X) -> io:format(S, "~p.~n", [X]) end, List),
	file:close(S).

coalesce(_, _, Number, LocalDict, _, Number) ->		%迭代到头了,将索引输出
	List=dict:to_list(LocalDict),
	unconsult(List);
coalesce(L, N, Number, LocalDict, Divisor, CoreDifference) ->
	if
		(N-1) rem Divisor =:= 0 -> 	%该进程应当接收
			receive
				{giveYou, Id, Dict}	->
					if
						Id-N =:= CoreDifference ->
							io:format("core~p, union with core ~p~n", [N-1, Id-1]),
							TotalDict=dict:merge(fun(K, V1, V2) -> V1++V2 end, LocalDict, Dict),
							coalesce(L, N, Number, TotalDict, Divisor*2, CoreDifference*2); %倍增，迭代
						true ->
							io:format("error~n")
					end
			end;
		true ->			%该进程应当发送
			Pid=lists:nth(N-CoreDifference, L),
			Pid ! {giveYou, N, LocalDict}	%向接收进程发送，之后不再活跃
	end.

coreTask(N, Number, Name, Divisor, CoreDifference) ->	%初次迭代，需要进行计算		
	{ok, S}=file:open(Name, read),
	Line=io:get_line(S, ''),
	LocalDict=getIndex(N, S, Line, 1, dict:new()),
	receive				%等到中控进程发来所有进程列表后继续
		{wholeList, L} ->
			if 
				(N-1) rem Divisor =:= 0 -> 	%该进程应当接收
					receive
						{giveYou, Id, Dict}	->
							%io:format("this is area:~p~n", [Area]),
							if
								Id-N =:= CoreDifference ->
									io:format("core~p, union with core ~p~n", [N-1, Id-1]),
									TotalDict=dict:merge(fun(K, V1, V2) -> V1++V2 end, LocalDict, Dict),
									coalesce(L, N, Number, TotalDict, Divisor*2, CoreDifference*2); %倍增，迭代
								true ->
									io:format("error~n")
							end
					end;
				true ->			%该进程应当发送
					Pid=lists:nth(N-CoreDifference, L),
					Pid ! {giveYou, N, LocalDict}	%向接收进程发送，之后不再活跃
			end
	end.			