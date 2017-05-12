#ifndef INPUTS_MAP_H
#define INPUTS_MAP_H

#include "model/basic_types/event.h"
#include "model/fault_tree/input_sequence.h"
#include "model/basic_types/function.h"

class Inputs_Map : public function<Event,Input_Sequence>
{
public:
  Inputs_Map();
};

inline Inputs_Map::Inputs_Map()
{
}

#endif // INPUTS_MAP_H
