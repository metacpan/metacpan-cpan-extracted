#include "model/basic_types/event.h"
#include <iostream>
#include <sstream>

unsigned long int Event::max_allocated = 0;
std::set<unsigned long int>* Event::reclaimed_ids = NULL;
function<unsigned long int, unsigned long int>* Event::references = NULL;

// ----------------------------------------------------------------------------------

std::ostream& operator<< (std::ostream& in_ostream, const Event& in_event)
{
  std::ostringstream temp_string;
  temp_string << in_event.id;

  in_ostream << temp_string.str();

  return in_ostream;
}

// ----------------------------------------------------------------------------------

Event::Event()
{
  // Allocate the static members if necessary
  if (references == NULL)
  {
    references = new function<unsigned long int, unsigned long int>;
    reclaimed_ids = new std::set<unsigned long int>;
  }

  if ((*reclaimed_ids).empty())
  {
    id = max_allocated;
    max_allocated++;
  }
  else
  {
    id = *((*reclaimed_ids).begin());
    (*reclaimed_ids).erase((*reclaimed_ids).begin());
  };

  Increase_Reference_Count();
}

// ----------------------------------------------------------------------------------

Event::Event(const Event &in_event)
{
  id = in_event.id;

  Increase_Reference_Count();
}

// ----------------------------------------------------------------------------------

Event::~Event()
{
  Decrease_Reference_Count();

  // Delete the static members if we don't need them any more. This is
  // somewhat inefficient if repeatedly create and destroy only one instance
  // of this class (but that is rare).
  if ((*references).size() == 0)
  {
    delete references;
    references = NULL;
    delete reclaimed_ids;
    reclaimed_ids = NULL;
  }
}
