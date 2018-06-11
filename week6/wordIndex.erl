-module(wordIndex).
-compile([export_all]).

start() ->
	io:format("please input file number:~n"),
	{_, NL}=io:fread("", "~d"),
	N=lists:nth(1, NL),
	NameList=readList(N, []),
%	printList(NameList),
	CoreList=create(N, N, NameList, []),		%��������
	tellEveryOne(CoreList, CoreList).	%�������б����ÿһ������

readList(0, L) ->
	L;
readList(N, L) ->
	{_, TmpList}=io:fread("", "~s"),
	readList(N-1, [lists:nth(1, TmpList)|L]).

create(0, _, _, L) ->
	L;
create(N, Number, [H|T], L) ->
	Pid=spawn(fun() -> coreTask(N, Number, H, 2, 1) end),	%�����ļ���
	create(N-1, Number, T, [Pid|L]).		%���������б�

tellEveryOne([], _) ->
	ok;
tellEveryOne([H|T], L) ->
	H ! {wholeList, L},
	tellEveryOne(T, L).

%����һ���ڵ��ֵ�
getThisLine(_, _, [], NowDict)->
	NowDict;
getThisLine(N, LineNumber, [H|T], NowDict)->
	Find=dict:find(H, NowDict),
	if
		Find =:= error ->	%�������ڸ��е��ֵ���
			NewDict=dict:store(H, [{N, LineNumber, 1}], NowDict); %һ��ʼ�ʹ�ɰ���tuple��list���ļ��š��кš���Ŀ
		true ->
			NewDict=dict:update(H, fun(V) -> %��number����һ
					{FileN, LineN, Time}=lists:nth(1, V),
					NewTup={FileN, LineN, Time+1},
					[NewTup]  end, NowDict)
	end,
	getThisLine(N, LineNumber, T, NewDict).

%ѭ�����ļ���ÿһ�н��д���
getIndex(_, _, eof, _, Dict) ->
	Dict;
getIndex(N, File, Line, LineNumber, Dict) ->
	LineList=string:tokens(Line," .,:;\"\n"),%���ո񡢶��š���š�ð�š��ֺš����Ž�һ�зָ��һ��list
	LocalDict=getThisLine(N, LineNumber, LineList, dict:new()),
	TotalDict=dict:merge(fun(K, V1, V2) -> V1++V2 end, LocalDict, Dict),
	getIndex(N, File, io:get_line(File, ''), LineNumber+1, TotalDict).

unconsult(List) ->
	{ok, S}=file:open("output.txt", write),
	lists:foreach(fun(X) -> io:format(S, "~p.~n", [X]) end, List),
	file:close(S).

coalesce(_, _, Number, LocalDict, _, Number) ->		%������ͷ��,���������
	List=dict:to_list(LocalDict),
	unconsult(List);
coalesce(L, N, Number, LocalDict, Divisor, CoreDifference) ->
	if
		(N-1) rem Divisor =:= 0 -> 	%�ý���Ӧ������
			receive
				{giveYou, Id, Dict}	->
					if
						Id-N =:= CoreDifference ->
							io:format("core~p, union with core ~p~n", [N-1, Id-1]),
							TotalDict=dict:merge(fun(K, V1, V2) -> V1++V2 end, LocalDict, Dict),
							coalesce(L, N, Number, TotalDict, Divisor*2, CoreDifference*2); %����������
						true ->
							io:format("error~n")
					end
			end;
		true ->			%�ý���Ӧ������
			Pid=lists:nth(N-CoreDifference, L),
			Pid ! {giveYou, N, LocalDict}	%����ս��̷��ͣ�֮���ٻ�Ծ
	end.

coreTask(N, Number, Name, Divisor, CoreDifference) ->	%���ε�������Ҫ���м���		
	{ok, S}=file:open(Name, read),
	Line=io:get_line(S, ''),
	LocalDict=getIndex(N, S, Line, 1, dict:new()),
	receive				%�ȵ��пؽ��̷������н����б�����
		{wholeList, L} ->
			if 
				(N-1) rem Divisor =:= 0 -> 	%�ý���Ӧ������
					receive
						{giveYou, Id, Dict}	->
							%io:format("this is area:~p~n", [Area]),
							if
								Id-N =:= CoreDifference ->
									io:format("core~p, union with core ~p~n", [N-1, Id-1]),
									TotalDict=dict:merge(fun(K, V1, V2) -> V1++V2 end, LocalDict, Dict),
									coalesce(L, N, Number, TotalDict, Divisor*2, CoreDifference*2); %����������
								true ->
									io:format("error~n")
							end
					end;
				true ->			%�ý���Ӧ������
					Pid=lists:nth(N-CoreDifference, L),
					Pid ! {giveYou, N, LocalDict}	%����ս��̷��ͣ�֮���ٻ�Ծ
			end
	end.			