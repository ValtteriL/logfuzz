% fuzz
% +MonitorHost host of the monitor process
% +MonitorPort port of the monitor process
% +TargetHost host of the target process
% +TargetPort port of the target process
fuzz(MonitorHost, MonitorPort, TargetHost, TargetPort) :-
    % connect to process monitor
    setup_call_cleanup(
        tcp_connect(MonitorHost:MonitorPort, MonitorStream, []),
        start_session(MonitorStream, TargetHost, TargetPort),
        close(MonitorStream)).

% start_session start fuzzing session
% +MonitorStream - socket stream to process monitor 
% +TargetHost - host of the target process
% +TargetPort - port of the target process
start_session(MonitorStream, TargetHost, TargetPort) :-
    % connect to target
    setup_call_cleanup(
        tcp_connect(TargetHost:TargetPort, FuzzStream, []),
        conversation(MonitorStream, FuzzStream),
        close(FuzzStream)).

% conversation between server and client
% +MonitorStream - socket stream to process monitor
% +FuzzStream - socket stream to target process
conversation(MonitorStream, FuzzStream) :-

    % TODO what to do if the target process has crashed
    string(Message),
    send(FuzzStream, Message),
    target_alive(MonitorStream).




% send sends message to socket
% +StreamPair - socket stream
% +Message - message to send
send(StreamPair, Message) :-
    format(StreamPair, Message, []),
    flush_output(StreamPair).


% check if target process is still alive
% +StreamPair - socket stream
target_alive(StreamPair) :-
    format(StreamPair, 'alive', []),
    flush_output(StreamPair),
    get_char(StreamPair, 'y'). % use line oriented instead
    

% strings
string('AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA').
string('BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB').

% integers
fuzz_integer(-1).
fuzz_integer(0).
fuzz_integer(-9999).
fuzz_integer(9999).

% bytes
