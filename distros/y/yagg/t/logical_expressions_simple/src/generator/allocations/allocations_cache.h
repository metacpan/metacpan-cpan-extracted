#ifndef DISABLE_ALLOCATION_CACHING_OPTIMIZATION

#ifndef ALLOCATIONS_CACHE_H
#define ALLOCATIONS_CACHE_H

#include <map>
#include <list>
#include <vector>

using namespace std;

#include "generator/shared/searchable_list"

class Rule_List;

class Allocations_Cache
{
public:
  void Store_Allocations(const Rule_List &in_rule_list);

  const bool Is_Finalized(const Rule_List &in_rule_list) const;
  void Finalize(const Rule_List &in_rule_list);

  list< vector< unsigned int > >::const_iterator
      Get_Allocations_Iterator(const Rule_List &in_rule_list) const;
  list< vector< unsigned int > >::const_iterator
    End(const Rule_List &in_rule_list) const;

protected:
  static map< const char*, map< unsigned int, searchable_list< vector< unsigned int > > > >
    m_cache;
  static map< const char*, map< unsigned int, bool > >
    m_finalized;
};

#endif // ALLOCATIONS_CACHE_H

#endif // DISABLE_ALLOCATION_CACHING_OPTIMIZATION
