-module(processRing).
-compile([export_all]).

start(N, M, Message) ->
	RingList=createRing(N, []),
	deliverInRing(RingList, RingList, M, Message).
%	deliverMessage(RingList, M, Message).

createRing(0, L) -> 
	L;
createRing(N, L) ->
	Pid=spawn(fun loop/0),
%	io:format("this process is:~p~n",[Pid]),
	createRing(N-1, [Pid|L]).

loop() ->
	receive
		{From,Any} ->
			io:format("I'm ~p, Msg from ~p arrives: ~p~n", [self(), From, Any]),
			loop()
    	end.
 
deliverMessage(_, _, 0, _) ->
	ok;
deliverMessage(Host, [H|T], M, Msg) ->
	H ! {Host, Msg},
	deliverMessage(Host, T, M-1, Msg).

deliverInRing(_,[],_,_) ->
	ok;
deliverInRing(WholeList, [H|T], M, Message) ->
	if
		length(T)>(M-1) ->
			deliverMessage(H, T, M, Message),
			deliverInRing(WholeList, T, M, Message);
		true ->
			TmpList=T++lists:sublist(WholeList,M-length(T)),
%			io:format("!!!~p~n",[TmpList]),
			deliverMessage(H, TmpList, M, Message),
			deliverInRing(WholeList, T, M, Message)
	end.

