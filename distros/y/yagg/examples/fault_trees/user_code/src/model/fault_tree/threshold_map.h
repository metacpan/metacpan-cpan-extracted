#ifndef THRESHOLD_MAP_H
#define THRESHOLD_MAP_H

#include "model/basic_types/event.h"
#include "model/fault_tree/threshold.h"
#include "model/basic_types/function.h"

class Threshold_Map : public function<Event,Threshold>
{
public:
  Threshold_Map();
};

inline Threshold_Map::Threshold_Map()
{
}

#endif // THRESHOLD_MAP_H
