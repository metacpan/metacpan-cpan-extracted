# Tcp

`unievent::Tcp` is a stream that represents both TCP streams and servers.

# Synopsis

```cpp
```


Tcp handle allows to establish TCP-connection to local or remote machine.
It is able to work over IPv4 as well as over IPv6 protocols (aka dual stack mode),
the difference between them is abstracted from user.

The Tcp hanlde is inherited from [Stream](stream.md) where the most part of its functionality is documented.

# Methods

All methods of [Stream](stream.md) also apply.

## open
```cpp
virtual excepted<void, ErrorCode> open (sock_t socket, Ownership = Ownership::TRANSFER);
```

Open an existing file descriptor as TCP handle; it is expected that `socket` is valid stream socket.

Socket is checked for connectivity and appropriate properties (`readable`, `writable`, `connected`, `established`, etc) are set.

If ownership is set to `Ownership::TRANSFER` then the Tcp object handles lifetime of the `socket` and closes it when needed.
Otherwize it never closes the `socket` and user should do it manually.


## bind
```cpp
virtual excepted<void, ErrorCode> bind (const net::SockAddr&, unsigned flags = 0);
virtual excepted<void, ErrorCode> bind (string_view host, uint16_t port, const AddrInfoHints& hints = defhints, unsigned flags = 0);
```

Bind the handle to an address, determined by `host`, and the specified `port` or `SockAddr` object.

The `host` can be a domain name, human-readable IP address or special string `"*"`, which means "bind to every available network interface on the host".

`port` can be 0 in which case handle will be bound to a some available port. It can later be inspected via `tcp->sockaddr()->port()`;

If `host` is a domain name, it is synchronously resolved to address using the specified `hints`, see [Resolver](resolver.md) for the details.

`flags` is the flags for binding.
The only supported flag for now is `Flags::IPV6ONLY` in which case dual-stack support is disabled and only IPv6 is used.


## connect
```cpp
TcpConnectRequestSP connect ();
TcpConnectRequestSP connect (const net::SockAddr& sa, uint64_t timeout = 0);
TcpConnectRequestSP connect (const string& host, uint16_t port, uint64_t timeout = 0, const AddrInfoHints& hints = defhints);
```

Start connection process to the specified endpoint.

The `host` can be a domain name, human-readable IP address.
If `host` is a domain name, it is synchronously resolved to address using the specified `hints`, see [Resolver](resolver.md) for the details.

`timeout` is a timeout in milliseconds for the whole connection process (may be fractional).
This includes possible resolving process, establishing tcp connection and possible SSL handshake if in use
(i.e. full time until `connect_event` is called). [Stream](stream.md).

Default is 0 (no timeout).

The method returns immediately and provides `TcpConnectRequest` as the result, actual connection will be performed later durning even loop run.

## set_nodelay
```cpp
excepted<void, ErrorCode> set_nodelay (bool enable);
```

Enable / disable `TCP_NODELAY`, which disables(enables) Nagle’s algorithm on the handle.

## set_keepalive
```cpp
excepted<void, ErrorCode> set_keepalive (bool enable, unsigned int delay);
```

Enable / disable TCP keep-alive. `delay` is the initial delay in milliseconds, ignored when enable is `false`.

## set_simultaneous_accepts
```cpp
excepted<void, ErrorCode> set_simultaneous_accepts (bool enable)
```

Enable / disable simultaneous asynchronous accept requests that are queued by the
operating system when listening for new TCP connections.

This setting is used to tune a TCP server for the desired performance. Having
simultaneous accepts can significantly improve the rate of accepting connections
(which is why it is enabled by default) but may lead to uneven load distribution
in multi-process setups.

# Static Methods

## pair
```cpp
static excepted<std::pair<TcpSP, TcpSP>, ErrorCode>
pair (const LoopSP& = Loop::default_loop(), int type = SOCK_STREAM, int proto = PF_UNSPEC);

static excepted<std::pair<TcpSP, TcpSP>, ErrorCode>
pair (const TcpSP&, const TcpSP&, int type = SOCK_STREAM, int proto = PF_UNSPEC);
```

Creates pair of connected `Tcp` handles in a cross-platform way.