#ifndef BLOCK_SET_H
#define BLOCK_SET_H

#ifdef WIN32
// Suppress warnings about debug identifiers being truncated to 255 characters
#pragma warning (disable:4786)
#endif

#include <set>

using namespace std;

#include "rbd/block.h"

using namespace std;

class Block_Set : public set<Block>
{
public:
  friend ostream& operator<< (ostream& in_ostream, const Block_Set& in_block_set);
};

#endif // BLOCK_SET_H
