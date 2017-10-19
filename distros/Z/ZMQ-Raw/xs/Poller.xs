MODULE = ZMQ::Raw               PACKAGE = ZMQ::Raw::Poller

SV *
new (class)
	SV *class

	PREINIT:
		zmq_raw_poller *poller = NULL;

	CODE:
		Newxz (poller, 1, zmq_raw_poller);
		Newxz (poller->items, 1, zmq_pollitem_t);
		ZMQ_NEW_OBJ (RETVAL, "ZMQ::Raw::Poller", poller);
		poller->sockets = newAV();

	OUTPUT: RETVAL

void
add (self, socket, events)
	SV *self
	SV *socket
	short events

	PREINIT:
		zmq_raw_poller *poller = NULL;
		zmq_raw_socket *sock;
		zmq_pollitem_t i;
		SSize_t size;

	CODE:
		poller = ZMQ_SV_TO_PTR (Poller, self);
		sock = ZMQ_SV_TO_PTR (Socket, socket);

		i.socket = sock->socket;
		i.events = events;
		i.revents = 0;

		size = av_len (poller->sockets)+1;
		Renew (poller->items, size+1, zmq_pollitem_t);
		Copy (&i, &poller->items[size], 1, zmq_pollitem_t);

		SvREFCNT_inc (SvRV (socket));
		av_push (poller->sockets, SvRV (socket));

void
wait (self, timeout)
	SV *self
	long timeout

	PREINIT:
		int rc, i, count = 0;
		zmq_raw_poller *poller = NULL;
		SSize_t size;

	CODE:
		poller = ZMQ_SV_TO_PTR (Poller, self);

		size = av_len (poller->sockets)+1;
		rc = zmq_poll (poller->items, size, timeout);
		zmq_raw_check_error (rc);

		for (i = 0; i < size; ++i)
		{
			if (poller->items[i].revents)
				++count;
		}

		XSRETURN_IV (count);



void
events(self, socket)
	SV *self
	SV *socket

	PREINIT:
		zmq_raw_poller *poller = NULL;
		void *s = NULL;

		SSize_t i, size;

	CODE:
		poller = ZMQ_SV_TO_PTR (Poller, self);
		size = av_len (poller->sockets)+1;

		for (i = 0; i < size; ++i)
		{
			SV **item = av_fetch (poller->sockets, i, 0);
			if (item && *item && SvRV (socket) == *item)
			{
				XSRETURN_IV (poller->items[i].revents);
			}
		}

		XSRETURN_UNDEF;

void
DESTROY (self)
	SV *self

	PREINIT:
		zmq_raw_poller *poller;
		SV *item;

	CODE:
		poller = ZMQ_SV_TO_PTR (Poller, self);

		av_undef (poller->sockets);
		Safefree (poller);

