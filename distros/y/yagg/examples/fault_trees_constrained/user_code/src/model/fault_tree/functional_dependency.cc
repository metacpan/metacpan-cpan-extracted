#include "model/fault_tree/functional_dependency.h"

const Event& Functional_Dependency::Get_Trigger() const
{
  return first;
}

void Functional_Dependency::Set_Trigger (const Event& in_trigger)
{
  first = in_trigger;
}


const Input_Sequence& Functional_Dependency::Get_Dependents() const
{
  return second;
}

void Functional_Dependency::Set_Dependents (const Input_Sequence& in_dependents)
{
  second = in_dependents;
}
