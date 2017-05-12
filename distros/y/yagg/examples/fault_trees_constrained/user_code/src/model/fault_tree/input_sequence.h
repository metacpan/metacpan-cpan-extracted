#ifndef INPUT_SEQUENCE_H
#define INPUT_SEQUENCE_H

#ifdef WIN32
// Suppress warnings about debug identifiers being truncated to 255 characters
#pragma warning (disable:4786)
#endif

#include <fstream>

using namespace std;

#include "model/basic_types/searchable_list"
#include "model/basic_types/event.h"

class Input_Sequence : public searchable_list<Event>
{
public:
  friend ostream& operator<< (ostream& in_ostream, const Input_Sequence& in_input_sequence);
};

#endif // INPUT_SEQUENCE_H
