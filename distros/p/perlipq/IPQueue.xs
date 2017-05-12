/*
 * $Id: IPQueue.xs,v 1.20 2001/11/24 09:29:58 jmorris Exp $
 *
 * Copyright (c) 2000 James Morris <jmorris@intercode.com.au>
 * This code is GPL.
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "libipq.h"
#include <linux/netfilter.h>

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    case 'A':
	break;
    case 'B':
	break;
    case 'C':
	break;
    case 'D':
	break;
    case 'E':
	break;
    case 'F':
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
    	if (strEQ(name, "IPQ_COPY_META"))
    		return IPQ_COPY_META;
    	if (strEQ(name, "IPQ_COPY_PACKET"))
    		return IPQ_COPY_PACKET;
	break;
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	break;
    case 'N':
	if (strEQ(name, "NF_ACCEPT"))
		return NF_ACCEPT;
	if (strEQ(name, "NF_DROP"))
		return NF_DROP;
	break;	
    case 'O':
	break;
    case 'P':
	break;
    case 'Q':
	break;
    case 'R':
	break;
    case 'S':
	break;
    case 'T':
	break;
    case 'U':
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


/* IPQ context */
typedef struct ipqxs_ctx
{
	struct ipq_handle *handle;		/* C library handle */
	unsigned char *buf;			/* Packet buffer */
	size_t buflen;				/* Buffer size */
} ipqxs_ctx_t;

/* Packet message */
typedef ipq_packet_msg_t ipqxs_packet_t;

/* Minimum buffer size, big enough to hold metadata + netlink message header */
#define IPQXS_MIN_BUFLEN (sizeof (ipqxs_packet_t) + sizeof (struct nlmsghdr))


MODULE = IPTables::IPv4::IPQueue  PACKAGE = IPTables::IPv4::IPQueue

double
constant(name,arg)
	char *name
	int arg

ipqxs_ctx_t *
_ipqxs_init_ctx(flags, protocol)
	unsigned int flags
	unsigned int protocol
	CODE:
		RETVAL = (ipqxs_ctx_t *)safemalloc(sizeof(ipqxs_ctx_t));
		if (RETVAL == NULL) {
			warn("Unable to allocate context\n");
			XSRETURN_UNDEF;
		}
		
		Zero(RETVAL, 1, ipqxs_ctx_t);
		
		RETVAL->handle = ipq_create_handle(flags, protocol);
		if (RETVAL->handle == NULL) {
			Safefree(RETVAL);
			XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL

int
_ipqxs_set_mode (ctx, mode, range)
	ipqxs_ctx_t *ctx
	unsigned char mode
	size_t range
	PREINIT:
		size_t newlen;
	CODE:
		newlen = IPQXS_MIN_BUFLEN + range;
		if (ctx->buflen != newlen) {
			ctx->buf = (unsigned char *)saferealloc(ctx->buf, newlen);
			ctx->buflen = newlen;
			if (ctx->buf == NULL) {
				warn("Unable to allocate packet buffer");
				ctx->buflen = 0;
				XSRETURN_UNDEF;
			}
		}
		RETVAL = ipq_set_mode(ctx->handle, mode, range);
	OUTPUT:
		RETVAL

ipqxs_packet_t *
_ipqxs_get_message (ctx, timeout)
	ipqxs_ctx_t *ctx
	int timeout
	PREINIT:
		int status;
		char *CLASS = "IPTables::IPv4::IPQueue::Packet";
	CODE:
		status = ipq_read(ctx->handle, ctx->buf, ctx->buflen, timeout);
		if (status <= 0)
			XSRETURN_UNDEF;
			
		switch (ipq_message_type(ctx->buf)) {
		
			case IPQM_PACKET: {
				ipq_packet_msg_t *pm = ipq_get_packet(ctx->buf);
				unsigned int size = sizeof(ipqxs_packet_t) + pm->data_len;
				
				RETVAL = (ipqxs_packet_t *)safemalloc(size);
				if(RETVAL == NULL) {
					warn("Unable to allocate packet");
					XSRETURN_UNDEF;
				}
				Copy(pm, RETVAL, size, char);
				break;
			}
				
			case NLMSG_ERROR:
				errno = ipq_get_msgerr(ctx->buf);
				XSRETURN_UNDEF;
			
			default:
				XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL
	CLEANUP:
		SvTAINTED_on(ST(0));

int
_ipqxs_set_verdict(ctx, id, verdict, data_len, buf)
	ipqxs_ctx_t *ctx
	unsigned long id
	unsigned int verdict
	size_t data_len
	unsigned char *buf
	CODE:
		if (data_len == 0 || !buf)
			buf = NULL;
		
		RETVAL = ipq_set_verdict(ctx->handle, id, verdict, data_len, buf);
	OUTPUT:
		RETVAL
	        	
                                                                                		
void
_ipqxs_destroy_ctx(ctx)
	ipqxs_ctx_t *ctx
	CODE:
		if (ctx->buf)
			Safefree(ctx->buf);
		Safefree(ctx);
		
char *
_ipqxs_errstr()
	CODE:
		RETVAL = ipq_errstr();
	OUTPUT:
		RETVAL


MODULE = IPTables::IPv4::IPQueue  PACKAGE = IPTables::IPv4::IPQueue::Packet

# Accessors

unsigned long
packet_id(self)
	ipqxs_packet_t *self
	CODE:
		RETVAL = self->packet_id;
	OUTPUT:
		RETVAL

unsigned long
mark(self)
	ipqxs_packet_t *self
	CODE:
		RETVAL = self->mark;
	OUTPUT:
		RETVAL
		
long
timestamp_sec(self)
	ipqxs_packet_t *self
	CODE:
		RETVAL = self->timestamp_sec;
	OUTPUT:    
		RETVAL
		
long
timestamp_usec(self)
	ipqxs_packet_t *self
	CODE:
		RETVAL = self->timestamp_usec;
	OUTPUT:
		RETVAL

unsigned int
hook(self)
	ipqxs_packet_t *self
	CODE:
		RETVAL = self->hook;
	OUTPUT:
		RETVAL

char *
indev_name(self)
	ipqxs_packet_t *self
	CODE:
		RETVAL = self->indev_name;
	OUTPUT:
		RETVAL

char *
outdev_name(self)
	ipqxs_packet_t *self
	CODE:
		RETVAL = self->outdev_name;
	OUTPUT:
		RETVAL

unsigned short
hw_protocol(self)
	ipqxs_packet_t *self
	CODE:
		RETVAL = self->hw_protocol;
	OUTPUT:
		RETVAL

unsigned short
hw_type(self)
	ipqxs_packet_t *self
	CODE:
		RETVAL = self->hw_type;
	OUTPUT:
		RETVAL

unsigned char
hw_addrlen(self)
	ipqxs_packet_t *self
	CODE:
		RETVAL = self->hw_addrlen;
	OUTPUT:
		RETVAL

unsigned char *
hw_addr(self)
	ipqxs_packet_t *self
	CODE:
		ST(0) = sv_newmortal();
		sv_setpvn(ST(0), (void *)self->hw_addr, self->hw_addrlen);
		
size_t
data_len(self)
	ipqxs_packet_t *self
	CODE:
		RETVAL = self->data_len;
	OUTPUT:
		RETVAL

unsigned char *
payload(self)
	ipqxs_packet_t *self
	CODE:
		if (self->data_len == 0)
			XSRETURN_UNDEF;
		ST(0) = sv_newmortal();
		sv_setpvn(ST(0), (void *)self->payload, self->data_len);
		
# Need to provide a destructor for this object.
void
DESTROY(self)
	ipqxs_packet_t *self
	CODE:
		safefree((char *)self);
