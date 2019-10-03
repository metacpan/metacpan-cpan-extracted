#include <zmq.h>

#include <assert.h>
#include <stdlib.h>

#include "mutex.h"
#include "timers.h"


struct zmq_raw_timers
{
	zmq_raw_mutex *mutex;
	void *timers;
	int timer_count;
	void *thread;
	int running;

	zmq_raw_timer **last;
	int run_count;

	zmq_pollitem_t wakeup_item;
	void *wakeup_context;
	void *wakeup_send;
	void *wakeup_recv;
};

struct zmq_raw_timer
{
	int id;
	int running;
	int after;
	int interval;
	void *context;
	void *send;
	void *recv;
	void *recv_sv;
	zmq_raw_timers *timers;
};


static void timer_handler (int timer_id, void *arg);
static void timer_thread (void *arg);


zmq_raw_timers *zmq_raw_timers_create()
{
	int rc;
	zmq_raw_timers *timers;

	if ((timers = calloc (1, sizeof (zmq_raw_timers))) == NULL ||
		(timers->timers = zmq_timers_new()) == NULL ||
		(timers->wakeup_context = zmq_ctx_new()) == NULL ||
		(timers->wakeup_send = zmq_socket (timers->wakeup_context, ZMQ_PAIR)) == NULL ||
		(timers->wakeup_recv = zmq_socket (timers->wakeup_context, ZMQ_PAIR)) == NULL)
		goto on_error;

	if ((rc = zmq_bind (timers->wakeup_recv, "inproc://_wakeup")) < 0 ||
		(rc = zmq_connect (timers->wakeup_send, "inproc://_wakeup")) < 0)
		goto on_error;

	goto done;

on_error:
	zmq_close (timers->wakeup_recv);
	zmq_close (timers->wakeup_send);
	zmq_ctx_term (timers->wakeup_context);
	free (timers);
	return NULL;

done:
	timers->wakeup_item.events = ZMQ_POLLIN;
	timers->wakeup_item.socket = timers->wakeup_recv;
	timers->mutex = zmq_raw_mutex_create();
	timers->timer_count = 0;
	return timers;
}

void zmq_raw_timers_destroy (zmq_raw_timers *timers)
{
	assert (timers);
	assert (timers->timer_count == 0);

	zmq_raw_mutex_lock (timers->mutex);
	timers->running = 0;
	zmq_send_const (timers->wakeup_send, "", 1, ZMQ_DONTWAIT);
	zmq_raw_mutex_unlock (timers->mutex);

	if (timers->thread)
		zmq_threadclose (timers->thread);
	zmq_raw_mutex_destroy (timers->mutex);

	zmq_close (timers->wakeup_send);
	zmq_close (timers->wakeup_recv);
	zmq_ctx_term (timers->wakeup_context);
	zmq_timers_destroy (&timers->timers);

	free (timers);
}

static zmq_raw_timer *zmq_raw_timer_create (void *context, int after, int interval)
{
	int rc;
	char endpoint[64];
	static const int v = 1;
	static int id = 0;
	zmq_raw_timer *timer;

	assert (context);

	sprintf (endpoint, "inproc://_timer-%d", ++id);

	if ((timer = calloc (1, sizeof (zmq_raw_timer))) == NULL ||
		(timer->send = zmq_socket (context, ZMQ_PAIR)) == NULL ||
		(timer->recv = zmq_socket (context, ZMQ_PAIR)) == NULL)
		goto on_error;

	/* Setting an interval of 0 will block zmq_timers_execute! Always add 10ms */
	after += 10;

	timer->after = after;
	timer->interval = interval;

	if ((rc = zmq_bind (timer->recv, endpoint)) < 0 ||
		(rc = zmq_setsockopt (timer->recv, ZMQ_CONFLATE, &v, sizeof (v))) < 0 ||
		(rc = zmq_connect (timer->send, endpoint)) < 0)
		goto on_error;

	goto done;

on_error:
	zmq_close (timer->send);
	zmq_close (timer->recv);
	free (timer);
	return NULL;

done:
	return timer;
}

static void zmq_raw_timer_destroy (zmq_raw_timer *timer)
{
	assert (timer);
	assert (timer->send);

	zmq_close (timer->send);

	if (timer->recv && !timer->recv_sv)
		zmq_close (timer->recv);

	zmq_raw_mutex_lock (timer->timers->mutex);
	--timer->timers->timer_count;
	zmq_raw_mutex_unlock (timer->timers->mutex);

	free (timer);
}

static void zmq_raw_timers__start (zmq_raw_timer *timer)
{
	zmq_raw_timers *timers;
	assert (timer);
	assert (timer->timers);

	timers = timer->timers;

	timer->id = zmq_timers_add (timers->timers, timer->after, timer_handler, timer);
	timer->running = 1;

	if (!timers->running)
	{
		/* start the timer thread */
		timers->running = 1;
		timers->thread = zmq_threadstart (timer_thread, timers);
	}
	else
	{
		/* wakeup the timer thread */
		zmq_send_const (timers->wakeup_send, "", 1, ZMQ_DONTWAIT);
	}
}

zmq_raw_timer *zmq_raw_timers_start (zmq_raw_timers *timers, void *context, int after, int interval)
{
	int rc;
	zmq_raw_timer *timer;

	assert (timers);
	assert (context);

	zmq_raw_mutex_lock (timers->mutex);

	timer = zmq_raw_timer_create (context, after, interval);
	if (timer == NULL)
	{
		zmq_raw_mutex_unlock (timers->mutex);
		return NULL;
	}

	timer->timers = timers;
	zmq_raw_timers__start (timer);

	++timer->timers->timer_count;
	zmq_raw_mutex_unlock (timers->mutex);

	return timer;
}

void zmq_raw_timers_reset (zmq_raw_timer *timer)
{
	assert (timer);

	zmq_raw_mutex_lock (timer->timers->mutex);
	if (timer->running)
		zmq_timers_reset (timer->timers->timers, timer->id);
	else
		zmq_raw_timers__start (timer);

	while (zmq_recv (timer->recv, NULL, 0, ZMQ_DONTWAIT) == 0);
	zmq_raw_mutex_unlock (timer->timers->mutex);
}

static void zmq_raw_timers__stop (zmq_raw_timer *timer)
{
	assert (timer);

	if (timer->running)
	{
		timer->running = 0;
		/* explicitly set the interval to 0 so the next call
		 * to zmq_timers_execute() cleans up the cancelled
		 * timer immediately */
		zmq_timers_set_interval (timer->timers->timers, timer->id, 0);
		zmq_timers_cancel (timer->timers->timers, timer->id);
	}
}

static void zmq_raw_timers__expire (zmq_raw_timer *timer)
{
	if (timer->running)
	{
		zmq_raw_timers__stop (timer);

		timer->timers->last = NULL;
		timer->timers->run_count = 0;

		timer_handler (timer->id, timer);

		free (timer->timers->last);
	}
}

void zmq_raw_timers_expire (zmq_raw_timer *timer)
{
	assert (timer);

	zmq_raw_mutex_lock (timer->timers->mutex);
	zmq_raw_timers__expire (timer);
	zmq_raw_mutex_unlock (timer->timers->mutex);
}

void zmq_raw_timers_stop (zmq_raw_timer *timer)
{
	assert (timer);

	zmq_raw_mutex_lock (timer->timers->mutex);
	zmq_raw_timers__stop (timer);
	zmq_raw_mutex_unlock (timer->timers->mutex);
}

void zmq_raw_timers_remove (zmq_raw_timer *timer)
{
	assert (timer);

	zmq_raw_timers_stop (timer);
	zmq_raw_timer_destroy (timer);
}

int zmq_raw_timer_id (zmq_raw_timer *timer)
{
	assert (timer);
	return timer->id;
}

void *zmq_raw_timer_get_recv (zmq_raw_timer *timer)
{
	assert (timer);
	return timer->recv;
}

int zmq_raw_timer_is_running (zmq_raw_timer *timer)
{
	assert (timer);
	return timer->running;
}

void zmq_raw_timer_set_sv (zmq_raw_timer *timer, void *sv)
{
	assert (timer);
	assert (sv);
	assert (timer->recv_sv == NULL);

	timer->recv_sv = sv;
}

void *zmq_raw_timer_get_sv (zmq_raw_timer *timer)
{
	return timer->recv_sv;
}

void zmq_raw_timer_set_interval (zmq_raw_timer *timer, int interval)
{
	assert (timer);
	assert (interval > 0);

	zmq_raw_mutex_lock (timer->timers->mutex);
	timer->interval = interval;
	zmq_raw_mutex_unlock (timer->timers->mutex);
}

int zmq_raw_timer_get_interval (zmq_raw_timer *timer)
{
	int interval;
	assert (timer);

	zmq_raw_mutex_lock (timer->timers->mutex);
	interval = timer->interval;
	zmq_raw_mutex_unlock (timer->timers->mutex);

	return interval;
}

void timer_thread (void *arg)
{
	int count = 0, running = 1;
	long timeout;
	zmq_raw_timers *timers = (zmq_raw_timers *)arg;

	while (running)
	{
		zmq_raw_mutex_lock (timers->mutex);

		/* clear any 'pending' wakeup signals */
		while (zmq_recv (timers->wakeup_recv, NULL, 0, ZMQ_DONTWAIT) == 0);

		timers->last = NULL;
		timers->run_count = 0;
		zmq_timers_execute (timers->timers);

		while (--timers->run_count >= 0)
		{
			int index = timers->run_count;
			zmq_raw_timer *timer = timers->last[index];

			if (timer->interval == 0)
				zmq_raw_timers__stop (timer);
			else
				zmq_timers_set_interval (timers->timers, timer->id,
					(size_t)timer->interval);
		}

		if (timers->last)
			free (timers->last);

		running = timers->running;
		timeout = zmq_timers_timeout (timers->timers);
		zmq_raw_mutex_unlock (timers->mutex);

		/* sleep for 'timeout'. this may be interrupted
		 * by adding a new timer*/
		if (running)
			zmq_poll (&timers->wakeup_item, 1, timeout);
	}
}

void timer_handler (int timer_id, void *arg)
{
	assert (arg);

	/* this is guaranteed to execute with the timers mutex locked */
	zmq_raw_timer *timer = (zmq_raw_timer *)arg;

	assert (timer->id == timer_id);

	zmq_send_const (timer->send, "", 1, ZMQ_DONTWAIT);

	zmq_raw_timers *timers = timer->timers;
	int index = timers->run_count++;

	if (index == 0)
		timers->last = calloc (1, sizeof (zmq_raw_timer *));
	else
		timers->last = realloc (timers->last, timers->run_count*sizeof (zmq_raw_timer *));

	assert (timers->last);
	timers->last[index] = timer;
}
