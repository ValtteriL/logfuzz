#!/usr/bin/python3

import sys
import argparse
import socket
import subprocess
import shlex
import time
import logging

def go(command, port, delay):

    # start the process
    p = subprocess.Popen(shlex.split(command), stdout=None, stderr=subprocess.DEVNULL)

    # start listening for commands from the fuzzing engine
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", port))
        logging.info("Waiting for connection on 127.0.0.1:%s", port)
        s.listen()
        conn, addr = s.accept()
        with conn:
            logging.info('Connection received from %s', addr)
            while True:
                data = conn.recv(1024)

                if not data:
                    logging.info('Connection broken, stopping')
                    p.terminate()
                    break
                if b"restart" in data:
                    # start the process
                    p = subprocess.Popen(shlex.split(command), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    time.sleep(delay)

                    # if process is still alive after delay, return y, else n
                    if p.poll() is None:
                        conn.send(b"y")
                    else:
                        conn.send(b"n")
                if b"alive" in data:
                    # check if the target is alive
                    if p.poll() is None:
                        logging.info("no crash")
                        conn.send(b"y")
                    else:
                        logging.info("Crash detected")
                        conn.send(b"n")
                else:
                    logging.info('Received unknown message')
                    conn.send(b"Unknown message")





if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument('--command', '-C', help='process name to search for and attach to', metavar='NAME', required=True)
    parser.add_argument('--port', '-P', help='TCP port to bind this agent to', type=int, default=8888)
    parser.add_argument('--delay', '-D', help='Seconds to wait after starting program before answering its alive', type=int, default=3)
    args = parser.parse_args()

    logging.basicConfig(format='%(asctime)s - %(message)s', level=logging.INFO)

    go(args.command, args.port, args.delay)
