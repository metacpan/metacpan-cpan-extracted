#ifndef FUNCTIONAL_DEPENDENCY_H
#define FUNCTIONAL_DEPENDENCY_H

#ifdef WIN32
// Suppress warnings about debug identifiers being truncated to 255 characters
#pragma warning (disable:4786)
#endif

#include <utility>

using namespace std;

#include "model/basic_types/event.h"
#include "model/fault_tree/input_sequence.h"

class Functional_Dependency : public pair<Event, Input_Sequence>
{
public:
  const Event& Get_Trigger() const;
  void Set_Trigger (const Event& in_trigger);

  const Input_Sequence& Get_Dependents() const;
  void Set_Dependents (const Input_Sequence& in_dependents);
};

#endif // FUNCTIONAL_DEPENDENCY_H
