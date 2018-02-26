MODULE = ZMQ::Raw               PACKAGE = ZMQ::Raw::Context

SV *
new (class)
	SV *class

	PREINIT:
		int i;
		zmq_raw_context *ctx = NULL;

	CODE:
		Newxz (ctx, 1, zmq_raw_context);
		ctx->mutex = zmq_raw_mutex_create();
		ctx->context = zmq_ctx_new();
		ctx->reference_count = 1;
		ctx->timers = NULL;

		ZMQ_NEW_REFCOUNTED_OBJ (RETVAL, "ZMQ::Raw::Context",
			ctx, zmq_raw_ctx_dup);

	OUTPUT: RETVAL

void
set (self, option, value)
	SV *self
	int option
	int value

	PREINIT:
		int rc;
		zmq_raw_context *ctx;

	CODE:
		ctx = ZMQ_SV_TO_PTR (Context, self);
		rc = zmq_ctx_set (ctx->context, option, value);
		zmq_raw_check_error (rc);

void
shutdown (self)
	SV *self

	PREINIT:
		int rc;
		zmq_raw_context *ctx;

	CODE:
		ctx = ZMQ_SV_TO_PTR (Context, self);
		rc = zmq_ctx_shutdown (ctx->context);
		zmq_raw_check_error (rc);

void
DESTROY(self)
	SV *self

	PREINIT:
		zmq_raw_context *ctx;

	CODE:
		ctx = ZMQ_SV_TO_PTR (Context, self);

		zmq_raw_mutex_lock (ctx->mutex);
		if (--ctx->reference_count > 0)
		{
			zmq_raw_mutex_unlock (ctx->mutex);
			XSRETURN (0);
		}

		if (ctx->timers)
			zmq_raw_timers_destroy (ctx->timers);

		zmq_ctx_term (ctx->context);
		zmq_raw_mutex_unlock (ctx->mutex);
		zmq_raw_mutex_destroy (ctx->mutex);
		Safefree (ctx);

