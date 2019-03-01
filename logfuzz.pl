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

    % connect to target
    setup_call_cleanup(
        tcp_connect(TargetHost:TargetPort, FuzzStream, []),
        conversation(MonitorStream, FuzzStream),
        close(FuzzStream)).



% define protocol messages
%
define_messages() :-
    string(Message),
    b_setval(one, Message).



% conversation between server and client
%
% +MonitorStream - socket stream to process monitor
% +FuzzStream - socket stream to target process
conversation(MonitorStream, FuzzStream) :-

    % TODO what to do if the target process has crashed
    b_getval(one, Message),
    send(FuzzStream, Message),
    
    get_char(FuzzStream, 'y'),

    send(FuzzStream, Message),
    target_alive(MonitorStream).


% send sends message to socket
%
% +StreamPair - socket stream
% +Message - message to send
send(StreamPair, Message) :-
    format(StreamPair, Message, []),
    flush_output(StreamPair).


% check if target process is still alive
%
% +StreamPair - socket stream
target_alive(StreamPair) :-
    format(StreamPair, 'alive', []),
    flush_output(StreamPair),
    (
        \+ get_char(StreamPair, 'y') % use line oriented instead
            -> logCrash(), restart_target(StreamPair), fail  % TODO: restart the process here
        ; true     
    ).
    

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
    (
        \+ get_char(StreamPair, 'y') % use line oriented instead
            -> true
        ;
        % restarting failed, abort
        writeln('Restarting target failed, aborting.'),
        abort
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
