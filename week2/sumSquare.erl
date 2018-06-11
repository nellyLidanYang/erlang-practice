-module(sumSquare).
-compile([export_all]).

sum(1) -> 1;
sum(N) -> math:pow(N, 2)+sum(N-1).