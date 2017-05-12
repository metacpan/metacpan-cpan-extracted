
#ifndef DESTS_MAP_H
#define DESTS_MAP_H

#include "rbd/block.h"
#include "rbd/block_set.h"
#include "basic_types/function.h"

class Dests_Map : public function<Block,Block_Set>
{
public:
  Dests_Map();
};

inline Dests_Map::Dests_Map()
{
}

#endif // DESTS_MAP_H
