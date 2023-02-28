#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#define NO_XSLOCKS
#include "XSUB.h"

#include "channel.h"

MODULE = Thread::GoChannel  PACKAGE = Thread::GoChannel  PREFIX = channel_

PROTOTYPES: DISABLED

SV* channel_new(SV* class)

void channel_send(Channel* channel, SV* argument)

SV* channel_receive(Channel* channel)

SV* channel_receive_ready_fh(Channel* channel)

SV* channel_send_ready_fh(Channel* channel)

void channel_close(Channel* channel)
