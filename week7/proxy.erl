-module(proxy).
-export([proxy/0]).

proxy()->
	%�����once�Ͳ��У�������˵ʲô��ͻ��ֻ����false
	{ok, Listen}=gen_tcp:listen(8080, [binary, {packet, 0}, {reuseaddr, true}, {active, true}]),
	io:format("start response~n"),
	spawn(fun() -> loop(Listen) end).%Ϊÿ�����󴴽��µĽ���������

loop(Listen)->
	{ok, Socket}=gen_tcp:accept(Listen),
	receive
		{tcp, Socket, Bin} ->
			[_, RawSite, _]=binary:split(Bin, [<<"Host: ">>, <<"\r\nProxy-Connection">>], [global]),
			RealSite=binary_to_list(RawSite),%chrome�����վ��
			io:format("~p~n", [RealSite]),
			Content=getContent(RealSite, Bin),
			io:format("proxy get the content~n"),
			gen_tcp:send(Socket, Content),%����ҳ���ݷ��ظ�chrome
	%		inet:setopts(Socket, [{active, once}]),
			loop(Socket);		
		{tcp_closed, Socket} ->
			io:format("server closed~p~n")
	end.

%��chrome�����վ���ȡ����
getContent(Site, Bin) ->
	io:format("%%%%%~n"),
	{ok, Socket}=gen_tcp:connect(Site, 80, [binary,{packet, 0}]),
	io:format("@@@@@~n"),
	ok=gen_tcp:send(Socket, Bin),
	receiveData(Socket, []).

receive_data(Socket, Data) ->
	receive
		{tcp, Socket, Bin} ->
			receive_data(Socket, [Bin|Data]);
		{tcp_closed, Socket} ->
			list_to_binary(reverse(Data))
	end.