#include <iostream>

using namespace std;

#include "model/fault_tree/input_sequence.h"

ostream& operator<< (ostream& in_ostream, const Input_Sequence& in_input_sequence)
{
  Input_Sequence::const_iterator an_event;
  for (an_event = in_input_sequence.begin(); an_event != in_input_sequence.end(); an_event++)
  {
    in_ostream << *an_event;

    Input_Sequence::const_iterator next_event(an_event);
    next_event++;
    if (next_event != in_input_sequence.end())
      in_ostream << ", ";
  }

  return in_ostream;
} 
