#pragma once

namespace panda { namespace unievent { namespace backend {

struct LoopImpl;
struct HandleImpl;

struct PrepareImpl;
struct IPrepareImplListener;

struct CheckImpl;
struct ICheckImplListener;

struct IdleImpl;
struct IIdleImplListener;

struct TimerImpl;
struct ITimerImplListener;

struct AsyncImpl;
struct IAsyncImplListener;

struct SignalImpl;
struct ISignalImplListener;

struct PollImpl;
struct IPollImplListener;

struct UdpImpl;
struct IUdpImplListener;
struct ISendListener;
struct SendRequestImpl;

struct StreamImpl;
struct IStreamImplListener;
struct IConnectListener;
struct ConnectRequestImpl;
struct IWriteListener;
struct WriteRequestImpl;
struct IShutdownListener;
struct ShutdownRequestImpl;

struct PipeImpl;
struct TcpImpl;
struct TtyImpl;

struct WorkImpl;
struct IWorkImplListener;

struct FsEventImpl;
struct IFsEventImplListener;

}}};
