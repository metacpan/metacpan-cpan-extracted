#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "channel.h"
#include "mthread.h"

#define slurp_arguments(offset) av_make(items - offset, PL_stack_base + ax + offset)

MODULE = Thread::Csp              PACKAGE = Thread::Csp  PREFIX = thread_

BOOT:
	global_init(aTHX);

Promise* thread_spawn(SV* class, SV* module, SV* function, ...)
	C_ARGS:
		slurp_arguments(1)

MODULE = Thread::Csp              PACKAGE = Thread::Csp::Promise  PREFIX = promise_

SV* promise_get(Promise* promise)

bool promise_is_finished(Promise* promise)

SV* promise_finished_fh(Promise* promise)

MODULE = Thread::Csp              PACKAGE = Thread::Csp::Channel  PREFIX = channel_

SV* channel_new(SV* class)

void channel_send(Channel* channel, SV* argument)

SV* channel_receive(Channel* channel)

SV* channel_receive_ready_fh(Channel* channel)

SV* channel_send_ready_fh(Channel* channel)

void channel_close(Channel* channel)
