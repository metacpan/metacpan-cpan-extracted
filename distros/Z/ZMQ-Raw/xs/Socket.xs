MODULE = ZMQ::Raw               PACKAGE = ZMQ::Raw::Socket

INCLUDE: const-xs-socket_options.inc

SV *
new (class, context, type)
	SV *class
	SV *context
	int type

	PREINIT:
		zmq_raw_socket *sock;
		zmq_raw_context *ctx;

	CODE:
		ctx = ZMQ_SV_TO_PTR (Context, context);
		Newxz (sock, 1, zmq_raw_socket);
		sock->type = type;
		sock->socket = zmq_socket (ctx->context, type);
		sock->context = ctx->context;
		if (sock->socket == NULL)
		{
			Safefree (sock);
			zmq_raw_check_error (-1);
		}

		ZMQ_NEW_OBJ_WITH_MAGIC (RETVAL, SvPVbyte_nolen (class), sock,
			SvRV (context));

	OUTPUT: RETVAL

void
bind (self, endpoint)
	SV *self
	const char *endpoint

	PREINIT:
		int rc;
		zmq_raw_socket *sock;

	CODE:
		sock = ZMQ_SV_TO_PTR (Socket, self);
		rc = zmq_bind (sock->socket, endpoint);
		zmq_raw_check_error (rc);

void
unbind (self, endpoint)
	SV *self
	const char *endpoint

	PREINIT:
		int rc;
		zmq_raw_socket *sock;

	CODE:
		sock = ZMQ_SV_TO_PTR (Socket, self);
		rc = zmq_unbind (sock->socket, endpoint);
		zmq_raw_check_error (rc);

void
connect (self, endpoint)
	SV *self
	const char *endpoint

	PREINIT:
		int rc;
		zmq_raw_socket *sock;

	CODE:
		sock = ZMQ_SV_TO_PTR (Socket, self);
		rc = zmq_connect (sock->socket, endpoint);
		zmq_raw_check_error (rc);

void
disconnect (self, endpoint)
	SV *self
	const char *endpoint

	PREINIT:
		int rc;
		zmq_raw_socket *sock;

	CODE:
		sock = ZMQ_SV_TO_PTR (Socket, self);
		rc = zmq_disconnect (sock->socket, endpoint);
		zmq_raw_check_error (rc);

void
send (self, buffer, flags=0)
	SV *self
	SV *buffer
	int flags

	PREINIT:
		int rc;
		zmq_raw_socket *sock;

	PPCODE:
		sock = ZMQ_SV_TO_PTR (Socket, self);
		rc = zmq_send (sock->socket,
			SvPVX (buffer), SvCUR (buffer), flags);
		if (rc < 0 && zmq_errno() == EAGAIN && (flags & ZMQ_DONTWAIT))
			XSRETURN_UNDEF;

		zmq_raw_check_error (rc);
		XSRETURN_YES;

void
sendmsg (self, ...)
	SV *self

	PREINIT:
		int rc, i;
		int flags = 0, count = 0;
		zmq_raw_socket *sock;

	PPCODE:
		if (items < 2)
			croak_usage ("not enough parameters provided");
		count = items-1;

		if (!sv_isobject (ST (items-1)) && SvIOK (ST (items-1)))
		{
			/* the last parameter looks like 'flags'. if all the preceding
			 * parameters are not ZMQ::Raw::Message objects, it is not
			 * 'flags'
			 */
			int is_flags = items-2 ? 1 : 0;
			for (i = 0; i < items-2; ++i && is_flags)
			{
				SV *item = ST (i+1);
				if (sv_isobject (item) && sv_derived_from (item, "ZMQ::Raw::Message"))
					continue;

				is_flags = 0;
			}

			if (is_flags)
			{
				flags = (int)SvIV (ST (items-1));
				--count;
			}
		}

		sock = ZMQ_SV_TO_PTR (Socket, self);
		for (i = 0; i < items && count; ++i)
		{
			zmq_msg_t msg;
			int extra = 0;
			SV *item = ST (i+1);

			if (--count > 0)
				extra = ZMQ_SNDMORE;

			if (sv_isobject (item) && sv_derived_from (item, "ZMQ::Raw::Message"))
			{
				rc = zmq_msg_init (&msg);
				zmq_raw_check_error (rc);

				rc = zmq_msg_copy (&msg, ZMQ_SV_TO_PTR (Message, item));
				if (rc < 0)
					zmq_msg_close (&msg);
				zmq_raw_check_error (rc);

	SENDMSG:
				rc = zmq_sendmsg (sock->socket, &msg, flags | extra);
				if (rc < 0)
				{
					int error = zmq_errno();
					zmq_msg_close (&msg);

					if (error == EAGAIN && (flags & ZMQ_DONTWAIT))
						XSRETURN_UNDEF;
				}
				zmq_raw_check_error (rc);

				rc = zmq_msg_close (&msg);
				zmq_raw_check_error (rc);
			}
			else
			{
				STRLEN size;
				const char *b = SvPV (item, size);

				rc = zmq_msg_init_size (&msg, size);
				zmq_raw_check_error (rc);

				Copy (b, zmq_msg_data (&msg), size, char);
				goto SENDMSG;
			}
		}

		XSRETURN_YES;

void
recv (self, flags=0)
	SV *self
	int flags

	PREINIT:
		int rc, ctx;
		int count = 0, more = 1;
		zmq_msg_t msg;
		zmq_raw_socket *sock;

	PPCODE:
		ctx = GIMME_V;

		sock = ZMQ_SV_TO_PTR (Socket, self);

		rc = zmq_msg_init (&msg);
		zmq_raw_check_error (rc);

		SV *buffer = sv_2mortal (newSV (16));
		SvPOK_on (buffer);
		SvCUR_set (buffer, 0);

		do
		{
			rc = zmq_recvmsg (sock->socket, &msg,
				flags);

			if (rc < 0)
			{
				int error = zmq_errno();
				zmq_msg_close (&msg);

				if (error == EAGAIN && (flags & ZMQ_DONTWAIT))
					XSRETURN_UNDEF;
			}
			zmq_raw_check_error (rc);

			sv_catpvn (buffer, zmq_msg_data (&msg), zmq_msg_size (&msg));

			more = zmq_msg_get (&msg, ZMQ_MORE);

			if (ctx == G_ARRAY)
			{
				++count;
				XPUSHs (buffer);
				buffer = NULL;

				if (more)
				{
					buffer = sv_2mortal (newSV (16));
					SvPOK_on (buffer);
					SvCUR_set (buffer, 0);
				}
			}
		}
		while (more);

		rc = zmq_msg_close (&msg);
		zmq_raw_check_error (rc);

		if (buffer)
		{
			++count;
			XPUSHs (buffer);
		}

		XSRETURN (count);

void
recvmsg (self, flags=0)
	SV *self
	int flags

	PREINIT:
		int rc, ctx;
		int count = 0, more = 1;
		zmq_msg_t msg;
		zmq_raw_socket *sock;

	PPCODE:
		ctx = GIMME_V;

		sock = ZMQ_SV_TO_PTR (Socket, self);

		rc = zmq_msg_init (&msg);
		zmq_raw_check_error (rc);

		while (more)
		{
			rc = zmq_recvmsg (sock->socket, &msg, flags);
			if (rc < 0)
			{
				int error = zmq_errno();
				zmq_msg_close (&msg);

				if (error == EAGAIN && (flags & ZMQ_DONTWAIT))
					break;
			}

			zmq_raw_check_error (rc);
			++count;

			{
				zmq_msg_t *obj;
				Newxz (obj, 1, zmq_msg_t);
				rc = zmq_msg_init (obj);
				zmq_raw_check_error (rc);

				rc = zmq_msg_copy (obj, &msg);
				zmq_raw_check_error (rc);

				SV *m;
				ZMQ_NEW_OBJ (m, "ZMQ::Raw::Message", obj);
				mXPUSHs (m);
			}

			more = zmq_msg_get (&msg, ZMQ_MORE);

			if (ctx != G_ARRAY)
				more = 0;
		}

		rc = zmq_msg_close (&msg);
		zmq_raw_check_error (rc);

		XSRETURN (count);

void
setsockopt (self, option, value)
	SV *self
	int option
	SV *value

	PREINIT:
		int rc;
		zmq_raw_socket *sock;

	CODE:
		sock = ZMQ_SV_TO_PTR (Socket, self);

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
			case ZMQ_CURVE_SERVER:
				{
					int v;
					if (!SvIOK (value))
						croak_usage ("Value is not an int");

					v = (int)SvIV (value);
					rc = zmq_setsockopt (sock->socket, option,
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
					rc = zmq_setsockopt (sock->socket, option,
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
			case ZMQ_CURVE_SECRETKEY:
			case ZMQ_CURVE_PUBLICKEY:
			case ZMQ_CURVE_SERVERKEY:
				{
					STRLEN len;
					char *buf;

					if (!SvPOK (value))
						croak_usage ("Value is not a string");

					buf = SvPV (value, len);
					rc = zmq_setsockopt (sock->socket, option,
						buf, len);
					zmq_raw_check_error (rc);
				}
				break;

			default:
				croak_usage ("Unsupported option");
		}

void
close (self)
	SV *self

	PREINIT:
		int rc;
		zmq_raw_socket *sock;

	CODE:
		sock = ZMQ_SV_TO_PTR (Socket, self);

		rc = zmq_close (sock->socket);
		zmq_raw_check_error (rc);

		sock->socket = zmq_socket (sock->context, sock->type);
		if (sock->socket == NULL)
			zmq_raw_check_error (-1);

void
monitor (self, endpoint, events)
	SV *self
	const char *endpoint
	int events

	PREINIT:
		int rc;
		zmq_raw_socket *sock;

	CODE:
		sock = ZMQ_SV_TO_PTR (Socket, self);

		rc = zmq_socket_monitor (sock->socket, endpoint, events);
		zmq_raw_check_error (rc);

void
join (self, group)
	SV *self
	const char *group

	PREINIT:
		int rc;
		zmq_raw_socket *sock;

	CODE:
		sock = ZMQ_SV_TO_PTR (Socket, self);

		rc = zmq_join (sock->socket, group);
		zmq_raw_check_error (rc);

void
leave (self, group)
	SV *self
	const char *group

	PREINIT:
		int rc;
		zmq_raw_socket *sock;

	CODE:
		sock = ZMQ_SV_TO_PTR (Socket, self);

		rc = zmq_leave (sock->socket, group);
		zmq_raw_check_error (rc);

void
DESTROY(self)
	SV *self

	PREINIT:
		zmq_raw_socket *sock;

	CODE:
		sock = ZMQ_SV_TO_PTR (Socket, self);
		if (sock->socket)
			zmq_close (sock->socket);
		Safefree (sock);
		SvREFCNT_dec (ZMQ_SV_TO_MAGIC (self));

