% fuzz
%
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
%
% +MonitorStream - socket stream to process monitor 
% +TargetHost - host of the target process
% +TargetPort - port of the target process
start_session(MonitorStream, TargetHost, TargetPort) :-

    % define protocol messages
    define_messages,

    % if target is not alive, restart it
    ( target_alive(MonitorStream)
    -> true
    ; restart_target(MonitorStream)
    ),

    % if multiple conversations, number them and go through numbers here. then call conversation(Stream, number)

    % connect to target
    setup_call_cleanup(
        tcp_connect(TargetHost:TargetPort, FuzzStream, []),
        catch(conversation(FuzzStream), _Error, true),
        close(FuzzStream)),

    % conversation succeeded until now, return true if the target has crashed
    \+ target_alive(MonitorStream).



% define protocol messages
%
define_messages() :-

    % splitmessage
    fuzz_integer(Int1),
    fuzz_integer(Int2),
    fuzz_integer(Int3),
    fuzz_integer(Int4),
    fuzz_integer(Int5),
    atom_concat(Int1, '#', Msg1),
    atom_concat(Msg1, Int2, Msg2),
    atom_concat(Msg2, '#', Msg3),
    atom_concat(Msg3, Int3, Msg4), 
    atom_concat(Msg4, '#', Msg5),
    atom_concat(Msg5, Int4, Msg6), 
    atom_concat(Msg6, '#', Msg7),
    atom_concat(Msg7, Int5, Msg8),
    b_setval(splitmessage, Msg8),

    % hellomessage
    string(HelloMsg); HelloMsg = 'hello',
    b_setval(hellomessage, HelloMsg),

    % onemessage
    string(OneMsg); OneMsg = 'one',
    b_setval(onemessage, OneMsg),

    % splitmessage reply
    Splitreply = Int1;
    Splitreply = Int2;
    Splitreply = Int3;
    Splitreply = Int4;
    Splitreply = Int5,
    b_setval(splitreply, Splitreply),

    b_setval(helloreply, 'hello'),
    b_setval(onereply, 'two').



% conversation between server and client
%
% +MonitorStream - socket stream to process monitor
% +FuzzStream - socket stream to target process
conversation(FuzzStream) :-


    writeln('first'),

    % send onemessage
    b_getval(onemessage, Message),
    send(FuzzStream, Message),

    % get onereply
    b_getval(onereply, Onereply),
    read_string(FuzzStream, _, Onereply),

    writeln('second'),

    % send hellomessage
    b_getval(hellomessage, Hellomessage),
    send(FuzzStream, Hellomessage),

    % get helloreply
    b_getval(helloreply, Helloreply),
    read_string(FuzzStream, _, Helloreply),

    writeln('third'),

    % send splitmessage
    b_getval(splitmessage, Splitmessage),
    send(FuzzStream, Splitmessage),

    % get splitreplies
    string_length(Splitmessage, Length),
    ReplyLength = Length - 4,
    read_string(FuzzStream, ReplyLength, _).




% send sends message to socket
%
% +StreamPair - socket stream
% +Message - message to send
send(StreamPair, Message) :-
    format(StreamPair, Message, []),
    flush_output(StreamPair).


% check if target process is still alive
% if not, log crash and restart target
%
% +StreamPair - socket stream
target_alive(StreamPair) :-
    format(StreamPair, 'alive', []),
    flush_output(StreamPair),
    get_char(StreamPair, 'y'). % use line oriented instead
    

% log data to file that caused crash
% each message is stored as <timestamp>_<message name>
logCrash() :- 
    get_time(Timestamp),
    nb_current(Name, Value),

    % build filename
    atom_concat('_', Name, Ending),
    atom_concat(Timestamp, Ending, Filename),

    setup_call_cleanup(
        open(Filename, write, Stream),
        write(Stream, Value),
        close(Stream)).


% restart target process
%
% +StreamPair - socket stream to process monitor
restart_target(StreamPair) :-
    format(StreamPair, 'restart', []),
    flush_output(StreamPair),

    ( get_char(StreamPair, 'y')
    -> true
    ; throw('Restarting target failed, aborting.')
    ).



% strings
string('AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA').
string('BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB').

% integers
fuzz_integer(-1).
fuzz_integer(0).
fuzz_integer(-9999).
fuzz_integer(9999).

% bytes
