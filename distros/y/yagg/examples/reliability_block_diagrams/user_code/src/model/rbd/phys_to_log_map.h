
#ifndef PHYS_TO_LOG_MAP_H
#define PHYS_TO_LOG_MAP_H

#include "rbd/block.h"
#include "rbd/component.h"
#include "rbd/block_set.h"
#include "basic_types/function.h"

class Phys_To_Log_Map : public function<Component,Block_Set>
{
public:
  Phys_To_Log_Map();
};

inline Phys_To_Log_Map::Phys_To_Log_Map()
{
}

#endif // PHYS_TO_LOG_MAP_H
