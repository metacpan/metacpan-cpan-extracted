#include <assert.h>
#include <stdlib.h>

#if _MSC_VER >= 1800 || __cplusplus > 199711L
#define HAVE_UNORDERED_MAP
#include <unordered_map>
#else
#include <map>
#endif

#include "eventmap.h"


namespace
{

#ifdef HAVE_UNORDERED_MAP
typedef std::unordered_map<void *, short> DataMap;
#else
typedef std::map<void *, short> DataMap;
#endif

}


struct zmq_raw_event_map: public DataMap
{
};

struct zmq_raw_event_map_iterator
{
	DataMap *map;
	DataMap::iterator it;
};


zmq_raw_event_map *zmq_raw_event_map_create()
{
	return new (std::nothrow) zmq_raw_event_map();
}

void zmq_raw_event_map_destroy (zmq_raw_event_map *map)
{
	delete map;
}

void zmq_raw_event_map_add (zmq_raw_event_map *map, void *ptr, short value)
{
	assert (map);

	map->insert (std::make_pair (ptr, value));
}

void zmq_raw_event_map_remove (zmq_raw_event_map *map, void *ptr)
{
	assert (map);

	DataMap::iterator it = map->find (ptr);
	if (it != map->end())
	{
		map->erase (it);
	}
}

const short *zmq_raw_event_map_get (zmq_raw_event_map *map, void *ptr)
{
	assert (map);

	DataMap::const_iterator it = map->find (ptr);
	if (it == map->end())
		return NULL;

	return &it->second;
}

void zmq_raw_event_map_clear (zmq_raw_event_map *map)
{
	assert (map);
	map->clear();
}

zmq_raw_event_map_iterator *zmq_raw_event_map_iterator_create (zmq_raw_event_map *map)
{
	assert (map);

	if (map->empty())
		return NULL;

	zmq_raw_event_map_iterator *iterator = new (std::nothrow) zmq_raw_event_map_iterator();
	if (iterator)
	{
		iterator->map = map;
		iterator->it = iterator->map->begin();
	}

	return iterator;
}

void zmq_raw_event_map_iterator_destroy (zmq_raw_event_map_iterator *iterator)
{
	delete iterator;
}

void *zmq_raw_event_map_iterator_next (zmq_raw_event_map_iterator *iterator)
{
	if (++iterator->it == iterator->map->end())
		return NULL;

	return iterator->it->first;
}

void *zmq_raw_event_map_iterator_key (zmq_raw_event_map_iterator *iterator)
{
	assert (iterator);
	return iterator->it->first;
}

