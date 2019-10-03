#ifndef LIBZMQRAW_TIMERS_H
#define LIBZMQRAW_TIMERS_H

typedef struct zmq_raw_timers zmq_raw_timers;
typedef struct zmq_raw_timer zmq_raw_timer;

zmq_raw_timers *zmq_raw_timers_create();
void zmq_raw_timers_destroy (zmq_raw_timers *timers);

zmq_raw_timer *zmq_raw_timers_start (zmq_raw_timers *timers, void *context, int after, int interval);
void zmq_raw_timers_reset (zmq_raw_timer *timer);
void zmq_raw_timers_stop (zmq_raw_timer *timer);
void zmq_raw_timers_expire (zmq_raw_timer *timer);
void zmq_raw_timers_remove (zmq_raw_timer *timer);

int zmq_raw_timer_id (zmq_raw_timer *timer);
void *zmq_raw_timer_get_recv (zmq_raw_timer *timer);
int zmq_raw_timer_is_running (zmq_raw_timer *timer);

void zmq_raw_timer_set_sv (zmq_raw_timer *timer, void *sv);
void *zmq_raw_timer_get_sv (zmq_raw_timer *timer);
void zmq_raw_timer_set_interval (zmq_raw_timer *timer, int interval);
int zmq_raw_timer_get_interval (zmq_raw_timer *timer);

#endif

