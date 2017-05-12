#ifndef EVENT_H
#define EVENT_H

#ifdef WIN32
// Suppress warnings about debug identifiers being truncated to 255 characters
#pragma warning (disable:4786)
#endif

#include <set>
#include "model/basic_types/function.h"
#include <cassert>

using namespace std;

// This class is a little more complicated that I would like. The static
// variables references and relaimed_ids must be pointers so that this class
// can explicitly manage the creation and destruction of the objects to which
// they point. If we used non-pointer objects, then the compiler may
// deallocate the variables before the last instance of this class is
// deallocated (causing the program to crash then the instance tries to
// decrease the reference count). [This was a 2-day bug. Can you tell?]

class Event
{
public:
  Event();
  Event(const Event& in_event);
  virtual ~Event();

  const Event& operator= (const Event &in_event);

  friend bool operator== (const Event& in_first, const Event& in_second);
  friend bool operator!= (const Event& in_first, const Event& in_second);
  friend bool operator< (const Event& in_first, const Event& in_second);
  friend ostream& operator<< (ostream& in_ostream, const Event& in_event);

protected:
  void Decrease_Reference_Count() const;
  void Increase_Reference_Count() const;

  // limit: up to ULONG_MAX event ids (and therefore events) as defined in
  // climits
  unsigned long int id;

  static unsigned long int max_allocated;
  static function<unsigned long int, unsigned long int>* references;
  static set<unsigned long int>* reclaimed_ids;
};

// ----------------------------------------------------------------------------------

inline bool operator==(const Event& in_first, const Event& in_second)
{
  return in_first.id == in_second.id;
}

// ----------------------------------------------------------------------------------

inline bool operator!=(const Event& in_first, const Event& in_second)
{
  return !(in_first.id == in_second.id);
}

// ----------------------------------------------------------------------------------

inline bool operator<(const Event& in_first, const Event& in_second)
{
  return in_first.id < in_second.id;
}

// ----------------------------------------------------------------------------------

inline const Event& Event::operator=(const Event& in_event)
{
  this->Decrease_Reference_Count();

  id = in_event.id;

  this->Increase_Reference_Count();

  return *this;
}

// ----------------------------------------------------------------------------------

inline void Event::Increase_Reference_Count() const
{
  if ((*references).find(id) == (*references).end())
    (*references)[id] = 1;
  else
    (*references)[id]++;
}

// ----------------------------------------------------------------------------------

inline void Event::Decrease_Reference_Count() const
{
  assert((*references)[id]>0);
  (*references)[id]--;

  if ((*references)[id] == 0)
  {
    (*reclaimed_ids).insert(id);
    (*references).erase(id);
  }
}

#endif // EVENT_H
