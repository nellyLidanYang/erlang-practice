-module(sum).
-compile([export_all]).

sum(N) ->
	0.5*N*(N+1).

sum(N,M) ->
	if
		N =< M ->
			0.5*(M-N+1)*(N+M);
		true ->
			io:format("N is not less than M~n")
	end.

sum1(1) -> 1;
sum1(N) -> N+sum(N-1).

sum1(N, N) -> N;
sum1(N, M) -> M+sum1(N, M-1).