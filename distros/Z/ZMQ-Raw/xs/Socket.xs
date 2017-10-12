MODULE = ZMQ::Raw               PACKAGE = ZMQ::Raw::Socket

INCLUDE: const-xs-socket_options.inc

SV *
new (class, ctx, type)
	SV *class
	SV *ctx
	int type

	PREINIT:
		void *sock = NULL;

	CODE:
		sock = zmq_socket (ZMQ_SV_TO_PTR (Context, ctx), type);
		if (sock == NULL)
		{
			zmq_raw_check_error (-1);
		}

		ZMQ_NEW_OBJ_WITH_MAGIC (RETVAL, SvPVbyte_nolen (class), sock,
			SvRV (ctx));

	OUTPUT: RETVAL

void
bind (self, endpoint)
	SV *self
	const char *endpoint

	PREINIT:
		int rc;

	CODE:
		rc = zmq_bind (ZMQ_SV_TO_PTR (Socket, self), endpoint);
		zmq_raw_check_error (rc);

void
unbind (self, endpoint)
	SV *self
	const char *endpoint

	PREINIT:
		int rc;

	CODE:
		rc = zmq_unbind (ZMQ_SV_TO_PTR (Socket, self), endpoint);
		zmq_raw_check_error (rc);

void
connect (self, endpoint)
	SV *self
	const char *endpoint

	PREINIT:
		int rc;

	CODE:
		rc = zmq_connect (ZMQ_SV_TO_PTR (Socket, self), endpoint);
		zmq_raw_check_error (rc);

void
disconnect (self, endpoint)
	SV *self
	const char *endpoint

	PREINIT:
		int rc;

	CODE:
		rc = zmq_disconnect (ZMQ_SV_TO_PTR (Socket, self), endpoint);
		zmq_raw_check_error (rc);

void
send (self, buffer, flags=0)
	SV *self
	SV *buffer
	int flags

	PREINIT:
		int rc;
		char *buf;
		STRLEN len;

	CODE:
		buf = SvPV (buffer, len);
		rc = zmq_send (ZMQ_SV_TO_PTR (Socket, self),
			buf, len, flags);
		zmq_raw_check_error (rc);

void
sendmsg (self, msg, flags=0)
	SV *self
	SV *msg
	int flags

	PREINIT:
		int rc;

	CODE:
		rc = zmq_sendmsg (ZMQ_SV_TO_PTR (Socket, self),
			ZMQ_SV_TO_PTR (Message, msg), flags);
		zmq_raw_check_error (rc);

SV *
recv (self, size=6, flags=0)
	SV *self
	int size
	int flags

	PREINIT:
		int rc;

	CODE:
		SV *buffer = newSV (size);
		SvPOK_on (buffer);
		SvCUR_set (buffer, 0);

		rc = zmq_recv (ZMQ_SV_TO_PTR (Socket, self),
			SvPVX (buffer), size, flags);
		if (rc == -1)
		{
			SvREFCNT_dec (buffer);
			zmq_raw_check_error (rc);
		}

		SvCUR_set (buffer, rc);
		RETVAL = buffer;

	OUTPUT: RETVAL

SV *
recvmsg (self, flags=0)
	SV *self
	int flags

	PREINIT:
		int rc;
		zmq_msg_t *msg;

	CODE:
		Newx (msg, 1, zmq_msg_t);

		rc = zmq_msg_init (msg);
		zmq_raw_check_error (rc);

		ZMQ_NEW_OBJ (RETVAL, "ZMQ::Raw::Message", msg);

		rc = zmq_recvmsg (ZMQ_SV_TO_PTR (Socket, self), msg,
			flags);
		zmq_raw_check_error (rc);

	OUTPUT: RETVAL

void
setsockopt (self, option, value)
	SV *self
	int option
	SV *value

	PREINIT:
		int rc;

	CODE:
		switch (option)
		{
			// int
			case ZMQ_BACKLOG:
			case ZMQ_CONFLATE:
			case ZMQ_CONNECT_TIMEOUT:
			case ZMQ_HANDSHAKE_IVL:
			case ZMQ_HEARTBEAT_IVL:
			case ZMQ_HEARTBEAT_TIMEOUT:
			case ZMQ_HEARTBEAT_TTL:
			case ZMQ_IMMEDIATE:
			case ZMQ_INVERT_MATCHING:
			case ZMQ_IPV6:
			case ZMQ_LINGER:
			case ZMQ_MULTICAST_HOPS:
			case ZMQ_MULTICAST_MAXTPDU:
			case ZMQ_PLAIN_SERVER:
			case ZMQ_USE_FD:
			case ZMQ_PROBE_ROUTER:
			case ZMQ_RATE:
			case ZMQ_RCVBUF:
			case ZMQ_RCVHWM:
			case ZMQ_RCVTIMEO:
			case ZMQ_RECONNECT_IVL:
			case ZMQ_RECONNECT_IVL_MAX:
			case ZMQ_RECOVERY_IVL:
			case ZMQ_REQ_CORRELATE:
			case ZMQ_REQ_RELAXED:
			case ZMQ_ROUTER_HANDOVER:
			case ZMQ_ROUTER_MANDATORY:
			case ZMQ_ROUTER_RAW:
			case ZMQ_SNDBUF:
			case ZMQ_SNDHWM:
			case ZMQ_SNDTIMEO:
			case ZMQ_STREAM_NOTIFY:
			case ZMQ_TCP_KEEPALIVE:
			case ZMQ_TCP_KEEPALIVE_CNT:
			case ZMQ_TCP_KEEPALIVE_IDLE:
			case ZMQ_TCP_KEEPALIVE_INTVL:
			case ZMQ_TCP_MAXRT:
			case ZMQ_TOS:
			case ZMQ_XPUB_VERBOSE:
			case ZMQ_XPUB_VERBOSER:
			case ZMQ_XPUB_MANUAL:
			case ZMQ_XPUB_NODROP:
				{
					int v;
					if (!SvIOK (value))
						croak_usage ("Value is not an int");

					v = SvIV (value);
					rc = zmq_setsockopt (ZMQ_SV_TO_PTR (Socket, self), option,
						&v, sizeof (v));
					zmq_raw_check_error (rc);
				}
				break;

			// int64
			case ZMQ_MAXMSGSIZE:
				{
					int64_t v;
					if (!SvIOK (value))
						croak_usage ("Value is not an int");

					v = SvIV (value);
					rc = zmq_setsockopt (ZMQ_SV_TO_PTR (Socket, self), option,
						&v, sizeof (v));
					zmq_raw_check_error (rc);
				}
				break;

			// binary
			case ZMQ_CONNECT_RID:
			case ZMQ_IDENTITY:
			case ZMQ_PLAIN_PASSWORD:
			case ZMQ_PLAIN_USERNAME:
			case ZMQ_SOCKS_PROXY:
			case ZMQ_SUBSCRIBE:
			case ZMQ_UNSUBSCRIBE:
			case ZMQ_XPUB_WELCOME_MSG:
			case ZMQ_ZAP_DOMAIN:
			case ZMQ_TCP_ACCEPT_FILTER:
				{
					STRLEN len;
					char *buf;

					if (!SvPOK (value))
						croak_usage ("Value is not a string");

					buf = SvPV (value, len);
					rc = zmq_setsockopt (ZMQ_SV_TO_PTR (Socket, self), option,
						buf, len);
					zmq_raw_check_error (rc);
				}
				break;

			default:
				croak_usage ("Unsupported option");
		}

void
DESTROY(self)
	SV *self

	PREINIT:
		int rc;

	CODE:
		rc = zmq_close (ZMQ_SV_TO_PTR (Socket, self));
		SvREFCNT_dec (ZMQ_SV_TO_MAGIC (self));
