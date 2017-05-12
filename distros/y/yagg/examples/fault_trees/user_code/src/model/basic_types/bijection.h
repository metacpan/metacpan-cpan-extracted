#ifndef BIJECTION_H
#define BIJECTION_H

#if defined(__sgi) && !defined(__GNUC__) && (_MIPS_SIM != _MIPS_SIM_ABI32)
#pragma set woff 1174
#pragma set woff 1375
#endif

#include "model/basic_types/function.h"
#include <set>

using namespace std;

// Doesn't actually ensure that the values in the range are unique

template <class _Key, class _Tp>
class bijection : public function<_Key,_Tp>
{
public:
  bijection()
  {
  }

  ~bijection()
  {
  }

  typename bijection<_Key,_Tp>::iterator inverse_find(const _Tp& in_argument)
  {
    typename bijection<_Key,_Tp>::iterator a_mapping;
    for (a_mapping = this->begin(); a_mapping != this->end(); a_mapping++)
    {
      if ((*a_mapping).second == in_argument)
        return a_mapping;
    }

    return this->end();
  }

  typename bijection<_Key,_Tp>::const_iterator inverse_find(const _Tp& in_argument) const
  {
    typename bijection<_Key,_Tp>::const_iterator a_mapping;
    for (a_mapping = this->begin(); a_mapping != this->end(); a_mapping++)
    {
      if ((*a_mapping).second == in_argument)
        return a_mapping;
    }

    return this->end();
  }

  const _Key inverse_apply(const _Tp& in_argument) const
  {
    typename bijection<_Key,_Tp>::const_iterator a_mapping;
    for (a_mapping = this->begin(); a_mapping != this->end(); a_mapping++)
    {
      if ((*a_mapping).second == in_argument)
        return (*a_mapping).first;
    }

    _Key temp;
    return temp;
  }

};

#endif // BIJECTION_H
