#include <cstdlib>
#include <typeinfo>

#ifndef DISABLE_ALLOCATION_CACHING_OPTIMIZATION

#include "generator/allocations/allocations_cache.h"
#include "generator/rule_list/rule_list.h"

#ifdef CACHING_TRACE
#include "generator/utility/utility.h"
#endif // CACHING_TRACE

map< const char*, map< unsigned int, searchable_list< vector< unsigned int > > > >
  Allocations_Cache::m_cache;
map< const char*, map< unsigned int, bool > > Allocations_Cache::m_finalized;

// ---------------------------------------------------------------------------

void Allocations_Cache::Store_Allocations(const Rule_List &in_rule_list)
{
  vector< unsigned int > allocations = in_rule_list.Get_Allocations();

  if (m_cache[typeid(in_rule_list).name()][
      in_rule_list.Get_Allowed_Length()].find(allocations) ==
      m_cache[typeid(in_rule_list).name()][
      in_rule_list.Get_Allowed_Length()].end())
  {
#ifdef CACHING_TRACE
    cerr << "CACHE: " << Utility::indent << "Storing " <<
      Utility::to_string(allocations.begin(), allocations.end()) << " for " <<
      Utility::readable_type_name(typeid(in_rule_list)) <<
      ", length " << in_rule_list.Get_Allowed_Length() << endl;
#endif // CACHING_TRACE

    m_cache[typeid(in_rule_list).name()][
      in_rule_list.Get_Allowed_Length()].push_back(allocations);
  }
  else
  {
#ifdef CACHING_TRACE
    cerr << "CACHE: " << Utility::indent << "Storing failed " <<
      Utility::to_string(allocations.begin(), allocations.end()) << " for " <<
      Utility::readable_type_name(typeid(in_rule_list)) <<
      ", length " << in_rule_list.Get_Allowed_Length() << 
      " (already in cache)" << endl;
#endif // CACHING_TRACE
  }
}

// ---------------------------------------------------------------------------

void Allocations_Cache::Finalize(const Rule_List &in_rule_list)
{
#ifdef CACHING_TRACE
  cerr << "CACHE: " << Utility::indent << "Finalizing cache for " <<
    Utility::readable_type_name(typeid(in_rule_list)) <<
    ", length " << in_rule_list.Get_Allowed_Length() << endl;
#endif // CACHING_TRACE

  m_finalized[typeid(in_rule_list).name()][in_rule_list.Get_Allowed_Length()] =
    true;
}

// ---------------------------------------------------------------------------

const bool Allocations_Cache::Is_Finalized(const Rule_List &in_rule_list) const
{
  if (m_finalized[typeid(in_rule_list).name()].find(in_rule_list.Get_Allowed_Length()) !=
      m_finalized[typeid(in_rule_list).name()].end())
    return true;
  else
    return false;
}

// ---------------------------------------------------------------------------

list< vector< unsigned int > >::const_iterator
    Allocations_Cache::Get_Allocations_Iterator(const Rule_List &in_rule_list) const
{
  return
    m_cache[typeid(in_rule_list).name()][in_rule_list.Get_Allowed_Length()].begin();
}

// ---------------------------------------------------------------------------

list< vector< unsigned int > >::const_iterator
  Allocations_Cache::End(const Rule_List &in_rule_list) const
{
  return
    (m_cache[typeid(in_rule_list).name()][in_rule_list.Get_Allowed_Length()]).end();
}

#endif // DISABLE_ALLOCATION_CACHING_OPTIMIZATION
