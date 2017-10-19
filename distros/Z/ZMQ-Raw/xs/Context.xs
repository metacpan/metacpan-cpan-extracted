MODULE = ZMQ::Raw               PACKAGE = ZMQ::Raw::Context

SV *
new (class)
	SV *class

	PREINIT:
		dMY_CXT;
		int i;
		zmq_raw_context *ctx = NULL;

	CODE:
		for (i = 0; i < MAX_CONTEXT_COUNT; ++i)
		{
			zmq_raw_context *tmp = &MY_CXT.contexts[i];
			if (tmp->context == NULL)
			{
				ctx = tmp;
				break;
			}
		}

		if (ctx == NULL)
			croak_usage ("too many contexts created");

		ctx->context = zmq_ctx_new();
		if (ctx->context == NULL)
			zmq_raw_check_error (-1);

		ctx->counter = zmq_atomic_counter_new();
		if (ctx->counter == NULL)
		{
			zmq_ctx_term (ctx->context);
			ctx->context = NULL;

			zmq_raw_check_error (-1);
		}

		zmq_atomic_counter_inc (ctx->counter);
		ZMQ_NEW_OBJ (RETVAL, "ZMQ::Raw::Context", ctx);

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
CLONE (...)
	PREINIT:
		dMY_CXT;
		int i;

	CODE:
		for (i = 0; i < MAX_CONTEXT_COUNT; ++i)
		{
			zmq_raw_context *ctx = &MY_CXT.contexts[i];
			if (ctx->counter)
				zmq_atomic_counter_inc (ctx->counter);
		}

void
DESTROY(self)
	SV *self

	PREINIT:
		dMY_CXT;
		zmq_raw_context *ctx;

	CODE:
		ctx = ZMQ_SV_TO_PTR (Context, self);

		if (zmq_atomic_counter_dec (ctx->counter) == 0)
		{
			zmq_atomic_counter_destroy (&ctx->counter);
			zmq_ctx_term (ctx->context);

			ctx->counter = NULL;
			ctx->context = NULL;
		}
