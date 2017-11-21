#ifndef LIBZMQRAW_MUTEX_H
#define LIBZMQRAW_MUTEX_H

typedef struct zmq_raw_mutex zmq_raw_mutex;

zmq_raw_mutex *zmq_raw_mutex_create();
void zmq_raw_mutex_destroy (zmq_raw_mutex *m);
void zmq_raw_mutex_lock (zmq_raw_mutex *m);
void zmq_raw_mutex_unlock (zmq_raw_mutex *m);

#endif

