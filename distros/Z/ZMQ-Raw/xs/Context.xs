MODULE = ZMQ::Raw               PACKAGE = ZMQ::Raw::Context

SV *
new (class)
	SV *class

	PREINIT:
		void *ctx = NULL;

	CODE:
		ctx = zmq_ctx_new();
		if (ctx == NULL)
		{
			zmq_raw_check_error (-1);
		}

		ZMQ_NEW_OBJ (RETVAL, SvPVbyte_nolen (class), ctx);

	OUTPUT: RETVAL

void
set (self, option, value)
	SV *self
	int option
	int value

	PREINIT:
		int rc;

	CODE:
		rc = zmq_ctx_set (ZMQ_SV_TO_PTR (Context, self), option, value);
		zmq_raw_check_error (rc);

void
shutdown (self)
	SV *self

	PREINIT:
		int rc;

	CODE:
		rc = zmq_ctx_shutdown (ZMQ_SV_TO_PTR (Context, self));
		zmq_raw_check_error (rc);

void
DESTROY(self)
	SV *self

	PREINIT:
		int rc;

	CODE:
		rc = zmq_ctx_term (ZMQ_SV_TO_PTR (Context, self));
