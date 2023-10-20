#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#define NO_XSLOCKS
#include "XSUB.h"

#define NEED_mg_findext
#include "ppport.h"

#include "channel.h"

typedef struct channel* Thread__GoChannel;

MODULE = Thread::GoChannel  PACKAGE = Thread::GoChannel  PREFIX = channel_

PROTOTYPES: DISABLED

Thread::GoChannel channel_new(SV* class)

void channel_send(Thread::GoChannel channel, SV* argument)

SV* channel_receive(Thread::GoChannel channel)

SV* channel_receive_ready_fh(Thread::GoChannel channel)

SV* channel_send_ready_fh(Thread::GoChannel channel)

void channel_close(Thread::GoChannel channel)
