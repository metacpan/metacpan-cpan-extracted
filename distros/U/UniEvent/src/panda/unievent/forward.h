#pragma once
#include <panda/refcnt.h>
#include <panda/log.h>

namespace panda { namespace unievent {

struct Loop;
using LoopSP = iptr<Loop>;

struct Handle;
using HandleSP = iptr<Handle>;

struct Prepare;
using PrepareSP = iptr<Prepare>;

struct Check;
using CheckSP = iptr<Check>;

struct Idle;
using IdleSP = iptr<Idle>;

struct Timer;
using TimerSP = iptr<Timer>;

struct Async;
using AsyncSP = iptr<Async>;

struct Signal;
using SignalSP = iptr<Signal>;

struct Poll;
using PollSP = iptr<Poll>;

struct Resolver;
using ResolverSP = iptr<Resolver>;

struct Udp;
using UdpSP = iptr<Udp>;

struct SendRequest;
using SendRequestSP = iptr<SendRequest>;

struct Stream;
using StreamSP = iptr<Stream>;

struct StreamFilter;
using StreamFilterSP = iptr<StreamFilter>;

struct StreamRequest;
using StreamRequestSP = iptr<StreamRequest>;

struct AcceptRequest;
using AcceptRequestSP = iptr<AcceptRequest>;

struct ConnectRequest;
using ConnectRequestSP = iptr<ConnectRequest>;

struct WriteRequest;
using WriteRequestSP = iptr<WriteRequest>;

struct ShutdownRequest;
using ShutdownRequestSP = iptr<ShutdownRequest>;

struct RunInOrderRequest;
using RunInOrderRequestSP = iptr<RunInOrderRequest>;

struct Pipe;
using PipeSP = iptr<Pipe>;

struct PipeConnectRequest;
using PipeConnectRequestSP = iptr<PipeConnectRequest>;

struct Tcp;
using TcpSP = iptr<Tcp>;

struct TcpConnectRequest;
using TcpConnectRequestSP = iptr<TcpConnectRequest>;

struct Work;
using WorkSP = iptr<Work>;

struct FsPoll;
using FsPollSP = iptr<FsPoll>;

struct FsEvent;
using FsEventSP = iptr<FsEvent>;

}}
