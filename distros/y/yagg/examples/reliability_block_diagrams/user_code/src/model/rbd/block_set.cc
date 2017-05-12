#include "rbd/block_set.h"
#include <iostream>

using namespace std;

ostream& operator<< (ostream& in_ostream, const Block_Set& in_block_set)
{
  Block_Set::const_iterator a_block;
  for (a_block = in_block_set.begin(); a_block != in_block_set.end(); a_block++)
  {
    in_ostream << *a_block;

    Block_Set::const_iterator next_block(a_block);
    next_block++;
    if (next_block != in_block_set.end())
      in_ostream << ", ";
  }

  return in_ostream;
} 
