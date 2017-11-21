#ifndef _WIN32
#include <pthread.h>
#else
#include <Windows.h>
#endif

#include <assert.h>
#include <stdlib.h>

#include "mutex.h"

struct zmq_raw_mutex
{
#ifdef _WIN32
	CRITICAL_SECTION m;
#else
	pthread_mutex_t m;
#endif
};


zmq_raw_mutex *zmq_raw_mutex_create()
{
	zmq_raw_mutex *m = malloc (sizeof (zmq_raw_mutex));
	#ifdef _WIN32
	InitializeCriticalSection (&m->m);
	#else
	int rc = pthread_mutex_init (&m->m, NULL);
	assert (rc == 0);
	#endif
	return m;
}

void zmq_raw_mutex_destroy (zmq_raw_mutex *m)
{
	#ifdef _WIN32
	DeleteCriticalSection (&m->m);
	#else
	int rc = pthread_mutex_destroy (&m->m);
	assert (rc == 0);
	#endif
	free (m);
}

void zmq_raw_mutex_lock (zmq_raw_mutex *m)
{
	#ifdef _WIN32
	EnterCriticalSection (&m->m);
	#else
	int rc = pthread_mutex_lock (&m->m);
	assert (rc == 0);
	#endif
}

void zmq_raw_mutex_unlock (zmq_raw_mutex *m)
{
	#ifdef _WIN32
	LeaveCriticalSection (&m->m);
	#else
	int rc = pthread_mutex_unlock (&m->m);
	assert (rc == 0);
	#endif
}

