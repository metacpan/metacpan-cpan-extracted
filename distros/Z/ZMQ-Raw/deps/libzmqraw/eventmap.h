#ifndef LIBZMQRAW_EVENTMAP_H
#define LIBZMQRAW_EVENTMAP_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct zmq_raw_event_map zmq_raw_event_map;

zmq_raw_event_map *zmq_raw_event_map_create();
void zmq_raw_event_map_destroy (zmq_raw_event_map *map);

void zmq_raw_event_map_add (zmq_raw_event_map *map, void *ptr, short value);
void zmq_raw_event_map_remove (zmq_raw_event_map *map, void *ptr);
const short *zmq_raw_event_map_get (zmq_raw_event_map *map, void *ptr);
void zmq_raw_event_map_clear (zmq_raw_event_map *map);

typedef struct zmq_raw_event_map_iterator zmq_raw_event_map_iterator;

zmq_raw_event_map_iterator *zmq_raw_event_map_iterator_create (zmq_raw_event_map *map);
void zmq_raw_event_map_iterator_destroy (zmq_raw_event_map_iterator *iterator);

void *zmq_raw_event_map_iterator_next (zmq_raw_event_map_iterator *iterator);
void *zmq_raw_event_map_iterator_key (zmq_raw_event_map_iterator *iterator);

#ifdef __cplusplus
}
#endif

#endif
