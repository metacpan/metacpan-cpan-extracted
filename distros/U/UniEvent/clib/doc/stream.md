# Stream

`unievent::Stream` - abstract handle of a duplex communication channel


The class shares common interface and implementation for the
[Tcp](tcp.md), [Pile](pipe.md) and [Tty](tty.md) handles.

The key feature of `unievent::Stream` that it is aimed to handle
connected-oriented full-duplex messaging aka streaming, i.e., first,
the connection should be established, and then traffic might flow
independently in both directions.

To use SSL with a stream, the `use_ssl()` method should
be invoked first, before binding/listening (for server) or
before connecting (for client).

It inherits [unievent::Handle](handle.md).


# Methods

All methods of [unievent::Handle](handle.md) also apply.

## read_start
```cpp
excepted<void, ErrorCode> read_start ();
```

Instructs the stream to watch for and read data from peer. Can only be called on readable and connected streams.

The `read_event`'s callbacks will be invoked when data arrives.

If you call this method when stream is not yet connected, it remembers your "wish" and will start reading when the stream is connected.

By default, all streams (except for `Tty`) "wishes" to read, so that normally you don't need to call this method by yourself.


## read_stop
```cpp
void read_stop ();
```

Stops watching for and reading data from the stream, and thus `read_event` callbacks will not be invoked from now on.

If you call this method before the stream is connected, it remembers your "wish" not to read data and thus `read_start` will not be automatically called
when the stream is connected.

You can call `read_start` later to start reading again.


## recv_buffer_size
```cpp
excepted<int,  ErrorCode> send_buffer_size () const;
excepted<void, ErrorCode> recv_buffer_size (int value);
```

Gets or sets the size of the receive buffer that the operating system uses for the stream.

## write
```cpp
virtual void   write (const WriteRequestSP&);

WriteRequestSP write (const string& buf, write_fn callback = nullptr);

template <class It>
WriteRequestSP write (const It& begin, const It& end, write_fn callback = nullptr);

template <class Range, typename = typename std::enable_if<std::is_convertible<decltype(*std::declval<Range>().begin()), string>::value>::type>
WriteRequestSP write (const Range& range, write_fn callback = nullptr);
```

Queues a write request to the stream. Request will be executed when all previous pending requests are done, so that it is possible to write data immediately,
even when stream is not yet connected. See [Request Queue](../README.md#request-queue)

One-shot `callback` will be invoked upon operation completion (see `write_event`).

Returns `WriteRequest` object which is an internal purpose object and returned for request tracking purposes only.


## write_queue_size
```cpp
size_t write_queue_size ()
```

Returns the amount of queued bytes waiting to be sent.


## send_buffer_size
```cpp
excepted<int,  ErrorCode> send_buffer_size () const { return make_excepted(impl()->send_buffer_size()); }
excepted<void, ErrorCode> send_buffer_size (int value) { return make_excepted(impl()->send_buffer_size(value)); }
```

Gets or sets the size of the send buffer that the operating system uses for the stream.

L<May return error|UniEvent/"OPTIONAL ERRORS">


## shutdown
```cpp
virtual void shutdown (const ShutdownRequestSP&);
void shutdown (shutdown_fn callback = {});
void shutdown (uint64_t timeout, shutdown_fn callback = {});
```

Queues a shutdown for the outgoing (write) side of a duplex stream. It waits for all pending requests to complete during `timeout` (if it is non-zero).
If timeout timer triggers, than all pending write requests are cancelled and the stream is shutdown by force.

When the operation is completed, EOF on the peer side will be triggered.

The `callback` is one-shot callback invoked upon operation completion (see `shutdown_event`).

Returns `ShutdownRequest` object which is an internal purpose object and returned for request tracking purposes only.

## disconnect
```cpp
virtual void disconnect ();
```

Queues a disconnect request.

The only exception is when the only pending request is a connect request. In this case, connect request is immediately cancelled, and the stream disconnects.

NOTE: if you want to immediately disconnect the stream cancelling all pending requests, call `Handle::reset()` or `Handle::clear()`.


## sockaddr
```cpp
virtual excepted<net::SockAddr, ErrorCode> sockaddr () const = 0;
```

Returns address of the **local** endpoint if possible.

If stream is not connected or not representable as sockaddr (windows named pipe, tty), undef is returned.

## peeraddr
```cpp
virtual excepted<net::SockAddr, ErrorCode> peeraddr () const = 0;
```

Returns address of the **remote** (peer) endpoint if possible.

If stream is not connected or not representable as sockaddr (windows named pipe, tty), undef is returned.


## event_listener
```cpp
IStreamListener* event_listener () const;
void             event_listener (IStreamListener* l);
```

Methods `on_establish`, `on_connection`, `on_connect`, `on_read`, `on_write`, `on_shutdown`, `on_eof` will be called.

Event `on_establish` is present only in event listener, not in event dispatcher version. It will be called (for client and server) when physical
connection is established (before possible SSL layer and so on).

See [Event Listener](../README.md#eventlistener).


## use_ssl
```cpp
void use_ssl (const SslContext& context);
void use_ssl (const SSL_METHOD* method = nullptr);
void no_ssl  ();
```

Enables SSL for the stream (adds SSL filter).

`ssl_context` is a RAII wrapper around `SSL*` from openssl.

For servers, SSL must be enabled on listening stream, not on individual connection streams. The same SSL context will be used for accepted streams.

`no_ssl()` disables SSL on the Stream.

Enabling or disabling  SSL can only be done in certain moments:

* For client streams, only before stream starts connecting or after it disconnects.

* For server stream, at any moment (further accepted connections will use SSL).

* For server connections (server-client streams), it is not possible as they are connected from the beginning and not used after disconnection. You must call this method on server listening stream.


## run_in_order
```cpp
template <class T> void run_in_order (T&& code);
```

Queues a callback to the stream. Callback will be invoked when all requests queued before this callback are done, but before requests queued after this callback
start executing.

```cpp
    tcp->connect(host, port);
    tcp->write("first");
    tcp->run_in_order([](const StreamSP&){/*any code*/});
    tcp->write("second");
```

In the example above, callback will be called after the stream is connected and sent first message. After calling callback, second message will be written.

In other words, `run_in_order` is the same as adding one more callback to the previous request.

Callback is invoked with a single argument - the stream object.

## listen

```cpp
virtual excepted<void, ErrorCode> listen (connection_fn callback = nullptr, int backlog = DEFAULT_BACKLOG);
excepted<void, ErrorCode>         listen (int backlog) { return listen(nullptr, backlog); }
```

Start listening for incoming connections (stream becomes a server). `backlog` indicates the number of
connections the kernel might queue. If `callback` is present, it is added as connection_event->add(callback).

May return an [error](https://github.com/CrazyPandaLimited/panda-lib/blob/master/doc/error.md#expect-the-expected)

## listening
```cpp
bool   listening        () const { return flags & LISTENING; }
```
Returns `true` if stream is listening for connections.

## connection_factory
```cpp
function<StreamSP(const StreamSP&)> connection_factory;
```

Allows for setting callback which will be called by server handle when new connection is accepted. This callback is expected to return a stream handle object
which will represent a client connection. This object must be of appropriate class ([Tcp](tcp.md), [Pipe](pipe.md)) or inherit from it. Object must be in initial state.

By default, if this factory callback is not set, UniEvent will create client handles as objects of default classes ([Tcp](tcp.md), [Pipe](pipe.md)).

Callback receives just one argument: server stream object.
```cpp
struct TcpTracer : Tcp {
    TcpTracer(LoopSP loop) : Tcp(loop) {
        std::cout << this  << " ctor";
    }

    ~TcpTracer() {
        std::cout << this  << " dtor";
    }
};
SockAddr sa; // some local addres

TcpSP server = new Tcp(loop);
server->bind(sa);
server->listen(1000);

server->connection_factory = [&](auto&){
    return new TcpTracer(server->loop());
};

server->connection_event.add([&](auto server, StreamSP sconn, auto err) {
    TcpTracerSP tracer = dynamic_pointer_cast<TcpTracer>(sconn);
    assert(tracer);
});

```

# Events

## connection_event
```cpp
CallbackDispatcher<void(const StreamSP& handle, const StreamSP& client, const ErrorCode& err)> connection_event;
```
Event will be invoked on servers when they establish new connection with client. Callbacks will be called only when both physical
and logical layers of connection are established (for example, for tcp ssl servers, when client tcp connection is established and ssl handshake is done).

Where `handle` is the server stream handle object which was listening.

`client` is newly created client stream handle object.

`error` is an optional `panda::ErrorCode` object and may present if there were any errors during physical or logical process of establishing connection.
In this case `client` may or may not be defined depending on state when error occured.

If you need to set earlier callback when physical layer is established, before logical, use `on_establish()` method override in `event_listener`.

See details about [event_listeners objects](../README.md#eventlistener)

## connect_event
```cpp
CallbackDispatcher<void(const StreamSP& handle, const ErrorCode& err, const ConnectRequestSP& req)> connect_event;
```

Event will be invoked on clients when they establish connection with server. Callbacks will be called only when both physical
and logical layers of connection are established (for example, for tcp ssl clients, when connection with server is established and ssl handshake is done).

Where `handle` is the server stream handle object which was listening.

`error` is an optional `panda::ErrorCode` object and may present if there were any errors during physical or logical process of establishing connection.

`connect_request` is an `ConnectRequest` object, which is an internal purpose object and passed to callback for request tracking purposes only.

## read_event
```cpp
CallbackDispatcher<void(const StreamSP& handle, string& buf, const ErrorCode& err)>       read_event;
```

Event will be invoked on readable connected streams when new data from peer has been read.

Where `handle` is the stream handle object.

`data` is the data has been read. May be empry if `error` occures.

`error` is an optional `panda::ErrorCode` object and may present if there were any errors during reading or processing data.

If the stream is readable and you didn't set any read callbacks (and didn't call [read_stop()](#read_stop)) then the stream will receive data from peer and discard it.
If you want to prevent peer from sending data to your stream call [read_stop()](#read_stop).

## write_event
```cpp
CallbackDispatcher<void(const StreamSP& handle, const ErrorCode& err, const WriteRequestSP& req)>      write_event;
```

Event will be invoked every time write operation caused by [write](#write) method is completed.

Where `handle` is the stream object.

`error` is an optional `ErrorCode` object.

`req` is an `WriteRequest` object, which is an internal purpose object and passed to callback for request tracking purposes only.

## shutdown_event

```cpp
CallbackDispatcher<void(const StreamSP& handle, const ErrorCode& err, const ShutdownRequestSP& req)>   shutdown_event;
```

The event will be invoked every time shutdown operation caused by [shutdown](#shutdown)> method is completed.

Where `handle` is the stream object.

`error` is an optional `ErrorCode` object.

`shutdown_request` is an ShutdownRequest object, which is an internal purpose object and passed to callback for request tracking purposes only.

## eof_event

```cpp
CallbackDispatcher<void(const StreamSP& handle)>        eof_event;
```

The event will be invoked when peer shuts down (i.e. no more data will be received) or disconnects.

# Flags


## connecting

Stream is currently connecting.


## established

Physical layer of the stream has succesfully connected to the peer.
It is `true`, for example, for ssl TCP connection, when tcp connection has been established, even if SSL-hanshake has not been done yet.

For basic handlers without SSL, the `connected and `established` coincide.


## connected

Logical layer of the stream has succesfully connected to the peer.
It is `true`, for example, for ssl TCP connection, when tcp connection has been established and SSL-hanshake has been done.

For basic handlers without SSL, the `connected` and `established` coincide.


## readable

Stream is readable.


## writable

Stream is writable.

## wantread

Stream is watching for incoming data (or will watch for it some time in the future in case if handle is not connected yet).

## shutting_down

Stream is currently shutting down.


## is_shut_down

Stream has been shut down.

## is_secure

Stream is using SSL.
