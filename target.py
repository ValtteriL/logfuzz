#!/usr/bin/python3

import sys
import argparse
import socket
import shlex
import time
import logging

def go(port):

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

                print(data)

                if not data:
                    logging.info('Connection broken, stopping')
                    p.terminate() # this crashes the process as it should
                    break
                if data == b"hello":
                    conn.send(b"hello")
                if data == b"one":
                    conn.send(b"two")
                if b"#" in data:
                    datastring = data.decode("utf-8")
                    datalist= datastring.split("#")
                    for i in datalist:
                        conn.send(i) 
                else:
                    logging.info('Received unknown message')
                    conn.send(b"Unknown message")





if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument('--port', '-P', help='TCP port to bind to', type=int, default=8888)
    args = parser.parse_args()

    logging.basicConfig(format='%(asctime)s - %(message)s', level=logging.INFO)

    print("STARTING TARGET ON PORT {}".format(args.port))

    go(args.port)
