#ifndef FUNCTION_H
#define FUNCTION_H

#include <map>
#include <set>
#include <cassert>
#include <iostream>

using namespace std;

template <class _Key, class _Tp>
class function : public map<_Key,_Tp>
{
public:
  function()
  {
  }

  virtual ~function()
  {
  }

  // This modifies the first argument instead of returning a value because we
  // don't know what type to return. For example, someone could pass something
  // which is of a class derived from function.
  friend void range_restrict(function<_Key, _Tp>& in_function, const set<_Tp>& in_range_set)
  {
    // We have to be careful deleting and incrementing iterators at the same
    // time. We could probably use remove_if, but I don't really have
    // experience with it...
    typename function<_Key,_Tp>::iterator a_mapping;
    for (a_mapping = in_function.begin(); a_mapping != in_function.end(); )
    {
      if (in_range_set.find((*a_mapping).second) == in_range_set.end())
        in_function.erase(a_mapping++);
      else
        ++a_mapping;
    }
  }

  // Overload ()
  virtual const _Tp& operator()(const _Key& in_argument) const
  {
    // Function applied to value outside its domain
    assert(this->find(in_argument) != this->end());
    
    return (this->find(in_argument))->second;
  }

  const set<_Key> domain() const
  {
    set<_Key> domain;

    typename function<_Key,_Tp>::const_iterator a_mapping;
    for (a_mapping = this->begin(); a_mapping != this->end(); a_mapping++)
    {
      domain.insert((*a_mapping).first);
    }

    return domain;
  }

  const set<_Tp> range() const
  {
    typename std::set<_Tp> range;

    typename function<_Key,_Tp>::const_iterator a_mapping;
    for (a_mapping = this->begin(); a_mapping != this->end(); a_mapping++)
    {
      range.insert((*a_mapping).second);
    }

    return range;
  }

  friend ostream& operator<< (ostream& in_ostream, const function<_Key,_Tp>& in_function)
  {
    in_ostream << "{" << endl;

    typename function<_Key,_Tp>::const_iterator a_mapping;
    for (a_mapping = in_function.begin(); a_mapping != in_function.end(); a_mapping++)
    {
      in_ostream << (*a_mapping).first << " -> " << (*a_mapping).second;

      typename function<_Key,_Tp>::const_iterator next_mapping(a_mapping);
      next_mapping++;
      if (next_mapping != in_function.end())
        in_ostream << ",";

      in_ostream << endl;
    }

    in_ostream << "}";

    return in_ostream;
  }
};

#endif // FUNCTION_H
