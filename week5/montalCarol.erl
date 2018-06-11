-module(montalCarol).
-compile([export_all]).

start(PointNumber, CoreNumber) ->
	CoreList=create(PointNumber, CoreNumber, CoreNumber, []),	%��������
	tellEveryOne(CoreList, CoreList).	%�������б����ÿһ������

create(_, 0, _, L) ->
	L;
create(PN, CN, CoreNumber, L) ->
	Pid=spawn(fun() -> coreTask(PN, CN, CoreNumber, 2, 1) end),
	create(PN, CN-1, CoreNumber, [Pid|L]).		%���������б�

tellEveryOne([], _) ->
	ok;
tellEveryOne([H|T], L) ->
	H ! {wholeList, L},
	tellEveryOne(T, L).

coalesce(L, CN, CoreNumber, LocalTarget, Divisor, CoreDifference, PointNumber) when CoreDifference =< CoreNumber ->
	if 
		(CN-1) rem Divisor =:= 0 -> 	%�ý���Ӧ������
			if
				CN-1+CoreDifference < CoreNumber ->	%���Ӧ�����յĽ����ж�Ӧ������̣����ֿ�
					receive
						{giveYou, Id, Target}	->
								io:format("core~p, union with core ~p~n", [CN-1, Id-1]),
								coalesce(L, CN, CoreNumber, LocalTarget+Target, Divisor*2, CoreDifference*2, PointNumber) %����������
					end;
				true ->	%���Ӧ�����յĽ����޶�Ӧ������̣��ֿ�
					coalesce(L, CN, CoreNumber, LocalTarget, Divisor*2, CoreDifference*2, PointNumber)
			end;
		true ->			%�ý���Ӧ������
			Pid=lists:nth(CN-CoreDifference, L),
			Pid ! {giveYou, CN, LocalTarget}	%����ս��̷��ͣ�֮���ٻ�Ծ
	end;
coalesce(_, _, _, LocalTarget, _, _, PointNumber)->
	io:format("total:~p~n", [LocalTarget]),
	io:format("Pi is about:~p~n", [4*LocalTarget/PointNumber]).

%������ɵ㲢�ۼ�����Բ�ڵ���Ŀ
getTarget(0, Target) ->
	Target;
getTarget(Times, Target) ->
	random:seed(erlang:phash2([node()]), erlang:monotonic_time(), erlang:unique_integer()),%��ÿ�����̷��䲻ͬ�������Ա�֤���ɵ��������ͬ
	X=random:uniform(),			%���������
	Y=random:uniform(),
	if
		((X-1)*(X-1)+(Y-1)*(Y-1)) =< 1 ->	%�����������Բ��
			getTarget(Times-1, Target+1);
		true ->
			getTarget(Times-1, Target)
	end.

coreTask(PN, CN, CoreNumber, Divisor, CoreDifference) ->	%���ε�������Ҫ���м���		
	LocalTarget=getTarget(PN div CoreNumber, 0),
	io:format("core~p, local target:~p~n", [CN-1, LocalTarget]),
	receive				%�ȵ��пؽ��̷������н����б�����
		{wholeList, L} ->
			if 
				(CN-1) rem Divisor =:= 0 -> 	%�ý���Ӧ������
					if
						CN-1+CoreDifference < CoreNumber ->	%���Ӧ�����յĽ����ж�Ӧ������̣����ֿ�
							receive
								{giveYou, Id, Target}	->
									io:format("~p get msg from core~p, target:~p~n", [CN-1, Id-1, Target]),
									io:format("core~p, union with core ~p~n", [CN-1, Id-1]),
									coalesce(L, CN, CoreNumber, LocalTarget+Target, Divisor*2, CoreDifference*2, PN)%����������
				
							end;
						true ->	
							io:format("im ~p~n", [CN-1]),			%���Ӧ�����յĽ����޶�Ӧ���̣��ֿ�
							coalesce(L, CN, CoreNumber, LocalTarget, Divisor*2, CoreDifference*2, PN)
					end;
				true ->	%�ý���Ӧ������
					io:format("sending:~p to ~p~n", [CN-1, CN-CoreDifference]),
					Pid=lists:nth(CN-CoreDifference, L),
					Pid ! {giveYou, CN, LocalTarget}	%����ս��̷��ͣ�֮���ٻ�Ծ
			end
	end.			