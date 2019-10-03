MODULE = ZMQ::Raw               PACKAGE = ZMQ::Raw::Timer

SV *
_new (class, context, after, interval)
	SV *class
	SV *context
	int after
	SV *interval

	PREINIT:
		zmq_raw_timer *timer;
		zmq_raw_context *ctx;
		zmq_raw_socket *sock;
		SV *sv;

	CODE:
		ctx = ZMQ_SV_TO_PTR (Context, context);

		zmq_raw_mutex_lock (ctx->mutex);
		if (ctx->timers == NULL)
		{
			ctx->timers = zmq_raw_timers_create();
			if (ctx->timers == NULL)
			{
				zmq_raw_mutex_unlock (ctx->mutex);
				zmq_raw_check_error (-1);
			}
		}
		zmq_raw_mutex_unlock (ctx->mutex);

		timer = zmq_raw_timers_start (ctx->timers, ctx->context,
			after, SvIOK (interval) ? SvIV (interval) : 0);
		if (timer == NULL)
			zmq_raw_check_error (-1);

		Newxz (sock, 1, zmq_raw_socket);
		sock->socket = zmq_raw_timer_get_recv (timer);

		ZMQ_NEW_OBJ_WITH_MAGIC (sv, "ZMQ::Raw::Socket", sock,
			SvRV (context));
		zmq_raw_timer_set_sv (timer, sv);

		ZMQ_NEW_OBJ_WITH_MAGIC (RETVAL, SvPVbyte_nolen (class), timer,
			SvRV (context));

	OUTPUT: RETVAL

void
id (self)
	SV *self

	PREINIT:
		zmq_raw_timer *timer;

	CODE:
		timer = ZMQ_SV_TO_PTR (Timer, self);
		XSRETURN_IV (zmq_raw_timer_id (timer));

SV *
running (self)
	SV *self

	PREINIT:
		zmq_raw_timer *timer;

	PPCODE:
		timer = ZMQ_SV_TO_PTR (Timer, self);
		if (zmq_raw_timer_is_running (timer))
			XSRETURN_YES;

		XSRETURN_NO;

int
interval (self, ...)
	SV *self

	PREINIT:
		int interval;
		zmq_raw_timer *timer;

	CODE:
		timer = ZMQ_SV_TO_PTR (Timer, self);

		if (items > 1)
		{
			if (!SvIOK (ST (1)) || SvIV (ST (1)) <= 0)
				croak_usage ("interval should be greater than zero");

			interval = SvIV (ST (1));
			zmq_raw_timer_set_interval (timer, interval);
		}

		RETVAL = zmq_raw_timer_get_interval (timer);

	OUTPUT: RETVAL

void
_cancel (self)
	SV *self

	PREINIT:
		zmq_raw_timer *timer;

	CODE:
		timer = ZMQ_SV_TO_PTR (Timer, self);

		zmq_raw_timers_stop (timer);

void
expire (self)
	SV *self

	PREINIT:
		zmq_raw_timer *timer;

	CODE:
		timer = ZMQ_SV_TO_PTR (Timer, self);

		zmq_raw_timers_expire (timer);

void
_reset (self)
	SV *self

	PREINIT:
		zmq_raw_timer *timer;

	CODE:
		timer = ZMQ_SV_TO_PTR (Timer, self);

		zmq_raw_timers_reset (timer);

SV *
socket (self)
	SV *self

	PREINIT:
		zmq_raw_timer *timer;
		SV *recv;

	CODE:
		timer = ZMQ_SV_TO_PTR (Timer, self);
		recv = MUTABLE_SV (zmq_raw_timer_get_sv (timer));

		SvREFCNT_inc (recv);
		RETVAL = recv;

	OUTPUT: RETVAL

void
DESTROY (self)
	SV *self

	PREINIT:
		zmq_raw_timer *timer;
		SV *recv;

	CODE:
		timer = ZMQ_SV_TO_PTR (Timer, self);
		recv = MUTABLE_SV (zmq_raw_timer_get_sv (timer));

		zmq_raw_timers_remove (timer);

		SvREFCNT_dec (recv);
		SvREFCNT_dec (ZMQ_SV_TO_MAGIC (self));

