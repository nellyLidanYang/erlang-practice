-module(sideEffect).
-compile([export_all]).

create(X) -> 
	if
		X =:=1 -> [1];
		X =/=1 -> create(X-1)++[X]
	end.

printNum([H|T]) ->
	io:format("Number:~p~n",[H]),
	printNum(T).

print_Ints(X) ->
	printNum(create(X)).


dealWithEven([H|T]) ->
	io:format("Even Number:~p~n",2*[H]),
	dealWithEven(T).
	
print_Even(X) ->
	if
		X rem 2 == 1 ->
			dealWithEven(create((X-1)/2));
		true ->
			dealWithEven(create(X/2))
	end.

print_Even1(1) -> ok;
print_Even1(N) when N rem 2 =:=0 ->
	io:format("Even Number:~p~n", [N]),
	print_Even1(N-1);
print_Even1(N) ->
	print_Even1(N-1).