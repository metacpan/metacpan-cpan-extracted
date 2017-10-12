MODULE = ZMQ::Raw               PACKAGE = ZMQ::Raw::Error

INCLUDE: const-xs-error.inc

SV *
message(self)
	SV *self

	PREINIT:
		zmq_raw_error *error;

	CODE:
		error = ZMQ_SV_TO_PTR (Error, self);
		SvREFCNT_inc (error -> message);
		RETVAL = error -> message;

	OUTPUT: RETVAL

SV *
code(self)
	SV *self

	PREINIT:
		zmq_raw_error *error;

	CODE:
		error = ZMQ_SV_TO_PTR (Error, self);
		RETVAL = newSViv (error -> code);

	OUTPUT: RETVAL

SV *
file(self)
	SV *self

	PREINIT:
		zmq_raw_error *error;

	CODE:
		error = ZMQ_SV_TO_PTR (Error, self);
		RETVAL = newSVpv (error -> file, 0);

	OUTPUT: RETVAL

SV *
line(self)
	SV *self

	PREINIT:
		zmq_raw_error *error;

	CODE:
		error = ZMQ_SV_TO_PTR (Error, self);
		RETVAL = newSVuv (error -> line);

	OUTPUT: RETVAL

void
DESTROY(self)
	SV *self

	PREINIT:
		zmq_raw_error *error;

	CODE:
		error = ZMQ_SV_TO_PTR (Error, self);
		SvREFCNT_dec (error -> message);
		Safefree (error);

