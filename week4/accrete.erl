-module(accrete).
-export([start/4]).

start(Fx, N, A, B) ->
	CoreList=create(Fx, N, N, A, B, []),	%��������
	tellEveryOne(CoreList, CoreList).	%�������б����ÿһ������

create(_, 0, _, _, _, L) ->
	L;
create(Fx, M, N, A, B, L) ->
	Pid=spawn(fun() -> coreTask(Fx, M, N, A, B, 2, 1) end),
	create(Fx, M-1, N, A, B, [Pid|L]).		%�������ڼ���Ľ����б�

tellEveryOne([], _) ->
	ok;
tellEveryOne([H|T], L) ->
	H ! {wholeList, L},
	tellEveryOne(T, L).

getArea(Fx, M, N, A, B) ->
	Width=(B-A)/N,
	0.5*(Fx(A+Width*(M-1))+Fx(A+Width*M))*Width.

coalesce(_, N, _, LocalArea, _, N) ->		%������ͷ��
	io:format("the total area is: ~p~n", [LocalArea]);
coalesce(L, N, M, LocalArea, Divisor, CoreDifference) ->
	if 
		(M-1) rem Divisor =:= 0 -> 	%�ý���Ӧ������
			receive
				{giveYou, Id, Area}	->
					if
						Id-M =:= CoreDifference ->
							io:format("block~p, union with block ~p~n", [M-1, Id-1]),
							TotalArea=LocalArea+Area,
							coalesce(L, N, M, TotalArea, Divisor*2, CoreDifference*2); %����������
						true ->
							io:format("error~n")
					end
			end;
		true ->			%�ý���Ӧ������
			Pid=lists:nth(M-CoreDifference, L),
			Pid ! {giveYou, M, LocalArea}	%����ս��̷��ͣ�֮���ٻ�Ծ
	end.

coreTask(Fx, M, N, A, B, Divisor, CoreDifference) ->	%���ε�������Ҫ���м���		
	LocalArea=getArea(Fx, M, N, A, B),
	io:format("block~p, this is local area:~p~n", [M-1, LocalArea]),
	receive				%�ȵ��пؽ��̷������н����б�����
		{wholeList, L} ->
			if 
				(M-1) rem Divisor =:= 0 -> 	%�ý���Ӧ������
					receive
						{giveYou, Id, Area}	->
							io:format("this is area:~p~n", [Area]),
							if
								Id-M =:= CoreDifference ->
									io:format("block~p, union with block ~p~n", [M-1, Id-1]),
									TotalArea=LocalArea+Area,
									coalesce(L, N, M, TotalArea, Divisor*2, CoreDifference*2); %����������
								true ->
									io:format("error~n")
							end
					end;
				true ->			%�ý���Ӧ������
					Pid=lists:nth(M-CoreDifference, L),
					Pid ! {giveYou, M, LocalArea}	%����ս��̷��ͣ�֮���ٻ�Ծ
			end
	end.			