MODULE = ZMQ::Raw               PACKAGE = ZMQ::Raw::Proxy

SV *
new (class)
	SV *class

	PREINIT:
		zmq_raw_proxy *proxy = NULL;

	CODE:
		Newxz (proxy, 1, zmq_raw_proxy);
		ZMQ_NEW_OBJ (RETVAL, "ZMQ::Raw::Proxy", proxy);

	OUTPUT: RETVAL

void
start (self, frontend, backend, ...)
	SV *self
	SV *frontend
	SV *backend

	PREINIT:
		zmq_raw_socket *f, *b, *c = NULL, *s = NULL;

	CODE:
		f = ZMQ_SV_TO_PTR (Socket, frontend);
		b = ZMQ_SV_TO_PTR (Socket, backend);
		if (SvOK (ST (3)))
			c = ZMQ_SV_TO_PTR (Socket, ST (3));
		if (SvOK (ST (4)))
			s = ZMQ_SV_TO_PTR (Socket, ST (4));
#ifdef USE_ITHREADS
		zmq_proxy_steerable (f->socket, b->socket,
			c ? c->socket : NULL,
			s ? s->socket : NULL);
#else
		croak_usage ("proxy requires interpreter threads");
#endif

