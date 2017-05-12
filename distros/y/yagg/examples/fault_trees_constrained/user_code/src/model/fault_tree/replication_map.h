#ifndef REPLICATION_MAP_H
#define REPLICATION_MAP_H

#include "model/basic_types/event.h"
#include "model/fault_tree/replication.h"
#include "model/basic_types/function.h"

class Replication_Map : public function<Event,Replication>
{
public:
  Replication_Map();
};

inline Replication_Map::Replication_Map()
{
}

#endif // REPLICATION_MAP_H
