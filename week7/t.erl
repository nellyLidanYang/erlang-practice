-module(t).
-export([start/0]).

start() ->
	{ok, Listen} = gen_tcp:listen(8080, [binary, {packet, 0}, {reuseaddr, true}, {active, true}]),
	spawn(fun() -> loop(Listen) end).

reverse([], R) -> R;
reverse([H|T], R) -> reverse(T, [H|R]).

reverse(L) -> reverse(L, []).

receive_data(Socket, Data) ->
	receive
		{tcp, Socket, Bin} ->
			receive_data(Socket, [Bin|Data]);
		{tcp_closed, Socket} ->
			list_to_binary(reverse(Data))
	end.
	
loop(Listen) ->	
	{ok, Socket} = gen_tcp:accept(Listen),
	spawn(fun() -> loop(Listen) end),
	receive
		{tcp, Socket, Bin} ->
			io:format("$$$$$$~n"),
			%io:format("tcp=~p~nSocket=~p~nHost=~p~n",[tcp, Socket, Bin]),
			%gen_tcp:connect("localhost", 1500, [binary, {packet, 0}]),
			[_, Host|_] = string:tokens(binary_to_list(Bin), "\r\n"),
			[_, Url|_] = string:tokens(Host, ": "),
			io:format("Url=~p~n",[Url]),
			{ok, Server} = gen_tcp:connect(Url, 80, [binary, {packet, 0}]),
			ok = gen_tcp:send(Server, "GET / HTTP/1.0\r\n\r\n"),
			Data = receive_data(Server, []),
			%io:format("Data=~p~n",[Data]),
			gen_tcp:send(Socket, Data),
			gen_tcp:close(Socket);
		{tcp_closed, Socket} -> ok
	end.