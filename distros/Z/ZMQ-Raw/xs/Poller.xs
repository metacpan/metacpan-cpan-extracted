MODULE = ZMQ::Raw               PACKAGE = ZMQ::Raw::Poller

SV *
new (class)
	SV *class

	PREINIT:
		zmq_raw_poller *poller = NULL;

	CODE:
		Newxz (poller, 1, zmq_raw_poller);
		poller->poller = zmq_poller_new();
		poller->events = zmq_raw_event_map_create();
		poller->interested = zmq_raw_event_map_create();
		if (poller->events == NULL || poller->interested == NULL || poller->poller == NULL)
		{
			zmq_raw_event_map_destroy (poller->events);
			zmq_raw_event_map_destroy (poller->interested);
			zmq_poller_destroy (&poller->poller);
			Safefree (poller);
			zmq_raw_check_error (-1);
		}

		ZMQ_NEW_OBJ (RETVAL, "ZMQ::Raw::Poller", poller);

	OUTPUT: RETVAL

void
add (self, socket, events)
	SV *self
	SV *socket
	short events

	PREINIT:
		zmq_raw_poller *poller;
		int rc;
		PerlIO *io;

	CODE:
		poller = ZMQ_SV_TO_PTR (Poller, self);

		io = zmq_get_socket_io (socket);
		if (io)
		{
			if (zmq_raw_event_map_get (poller->interested, SvRV (socket)))
				rc = zmq_poller_modify_fd (poller->poller, zmq_get_native_socket (io),
					events);
			else
				rc = zmq_poller_add_fd (poller->poller, zmq_get_native_socket (io),
					SvRV (socket), events);
			zmq_raw_check_error (rc);
		}
		else
		{
			zmq_raw_socket *sock = ZMQ_SV_TO_PTR (Socket, socket);

			if (zmq_raw_event_map_get (poller->interested, SvRV (socket)))
				rc = zmq_poller_modify (poller->poller, sock->socket,
					events);
			else
				rc = zmq_poller_add (poller->poller, sock->socket,
					SvRV (socket), events);
			zmq_raw_check_error (rc);
		}

		if (!zmq_raw_event_map_get (poller->interested, SvRV (socket)))
		{
			zmq_raw_event_map_add (poller->interested, SvRV (socket), events);
			SvREFCNT_inc (SvRV (socket));
			++poller->size;
		}

		if (poller->size > poller->allocated)
		{
			if (poller->poller_events)
				Safefree (poller->poller_events);

			Newxz (poller->poller_events, poller->size, zmq_poller_event_t);
			poller->allocated = poller->size;
		}


void
remove(self, socket)
	SV *self
	SV *socket

	PREINIT:
		zmq_raw_poller *poller;
		int rc;
		PerlIO *io;

	CODE:
		poller = ZMQ_SV_TO_PTR (Poller, self);

		io = zmq_get_socket_io (socket);
		if (io)
		{
			rc = zmq_poller_remove_fd (poller->poller, zmq_get_native_socket (io));
			if (rc != 0)
				XSRETURN_NO;
		}
		else
		{
			zmq_raw_socket *sock = ZMQ_SV_TO_PTR (Socket, socket);

			rc = zmq_poller_remove (poller->poller, sock->socket);
			if (rc != 0)
				XSRETURN_NO;
		}

		SvREFCNT_dec (SvRV (socket));
		--poller->size;

		zmq_raw_event_map_remove (poller->interested, SvRV (socket));

		XSRETURN_YES;

SV *
size (self)
	SV *self

	PREINIT:
		zmq_raw_poller *poller;
		SSize_t size;

	CODE:
		poller = ZMQ_SV_TO_PTR (Poller, self);
		RETVAL = newSViv ((IV)poller->size);

	OUTPUT: RETVAL

void
wait (self, timeout)
	SV *self
	long timeout

	PREINIT:
		int i, count, rc;
		zmq_raw_poller *poller = NULL;
		SSize_t size;

	CODE:
		poller = ZMQ_SV_TO_PTR (Poller, self);

		zmq_raw_event_map_clear (poller->events);

		rc = zmq_poller_wait_all (poller->poller, poller->poller_events, poller->size, timeout);
		if (rc < 0)
		{
			if (zmq_errno() == EAGAIN)
				XSRETURN_IV (0);

			zmq_raw_check_error (rc);
		}

		count = 0;

		for (i = 0; i < poller->size && rc; ++i)
		{
			zmq_poller_event_t *e = poller->poller_events+i;

			if (e->events)
			{
				const short *events = zmq_raw_event_map_get (poller->interested, e->user_data);
				assert (events);

				if (e->events & *events)
				{
					zmq_raw_event_map_add (poller->events, e->user_data, e->events & *events);
					++count;
				}

				--rc;
			}
		}

		XSRETURN_IV (count);

void
events(self, socket)
	SV *self
	SV *socket

	PREINIT:
		zmq_raw_poller *poller = NULL;
		const short *e;

	CODE:
		poller = ZMQ_SV_TO_PTR (Poller, self);

		if (!zmq_raw_event_map_get (poller->interested, SvRV (socket)))
			XSRETURN_UNDEF;

		e = zmq_raw_event_map_get (poller->events, SvRV (socket));
		if (e == NULL)
			XSRETURN_IV (0);

		XSRETURN_IV (*e);

void
DESTROY (self)
	SV *self

	PREINIT:
		zmq_raw_poller *poller;
		zmq_raw_event_map_iterator *iterator;

	CODE:
		poller = ZMQ_SV_TO_PTR (Poller, self);

		/* cleanup */
		iterator = zmq_raw_event_map_iterator_create (poller->interested);
		if (iterator)
		{
			do
			{
				SvREFCNT_dec (zmq_raw_event_map_iterator_key (iterator));
			}
			while (zmq_raw_event_map_iterator_next (iterator));

			zmq_raw_event_map_iterator_destroy (iterator);
		}

		zmq_raw_event_map_destroy (poller->interested);
		zmq_raw_event_map_destroy (poller->events);
		zmq_poller_destroy (&poller->poller);
		Safefree (poller);

