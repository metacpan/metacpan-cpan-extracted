#include <panda/unievent/backend/uv.h>
#include "UVBackend.h"
#include "UVUdp.h"
#include "UVTcp.h"
#include "UVTty.h"
#include "UVIdle.h"
#include "UVPoll.h"
#include "UVPipe.h"
#include "UVWork.h"
#include "UVTimer.h"
#include "UVCheck.h"
#include "UVAsync.h"
#include "UVSignal.h"
#include "UVDelayer.h"
#include "UVPrepare.h"
#include "UVFsEvent.h"

namespace panda { namespace unievent { namespace backend {

static uv::UVBackend _backend;

Backend* UV = &_backend;

}}}

namespace panda { namespace unievent { namespace backend { namespace uv {

TimerImpl*   UVLoop::new_timer     (ITimerImplListener* l)                      { return new UVTimer(this, l); }
PrepareImpl* UVLoop::new_prepare   (IPrepareImplListener* l)                    { return new UVPrepare(this, l); }
CheckImpl*   UVLoop::new_check     (ICheckImplListener* l)                      { return new UVCheck(this, l); }
IdleImpl*    UVLoop::new_idle      (IIdleImplListener* l)                       { return new UVIdle(this, l); }
AsyncImpl*   UVLoop::new_async     (IAsyncImplListener* l)                      { return new UVAsync(this, l); }
SignalImpl*  UVLoop::new_signal    (ISignalImplListener* l)                     { return new UVSignal(this, l); }
PollImpl*    UVLoop::new_poll_sock (IPollImplListener* l, sock_t sock)          { return new UVPoll(this, l, sock); }
PollImpl*    UVLoop::new_poll_fd   (IPollImplListener* l, int fd)               { return new UVPoll(this, l, fd, nullptr); }
UdpImpl*     UVLoop::new_udp       (IUdpImplListener* l, int domain, int flags) { return new UVUdp(this, l, domain, flags); }
PipeImpl*    UVLoop::new_pipe      (IStreamImplListener* l, bool ipc)           { return new UVPipe(this, l, ipc); }
TcpImpl*     UVLoop::new_tcp       (IStreamImplListener* l, int domain)         { return new UVTcp(this, l, domain); }
TtyImpl*     UVLoop::new_tty       (IStreamImplListener* l, fd_t fd)            { return new UVTty(this, l, fd); }
WorkImpl*    UVLoop::new_work      (IWorkImplListener* l)                       { return new UVWork(this, l); }
FsEventImpl* UVLoop::new_fs_event  (IFsEventImplListener* l)                    { return new UVFsEvent(this, l); }

}}}}
