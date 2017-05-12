#ifndef __TO_STRING_H__
#define __TO_STRING_H__

// http://www.s34.co.jp/cpptechdoc/reference/stl_samples/list.html

#include <sstream>  // ostringstream
#include <utility>  // pair

namespace Utility
{

template<class Iterator>
std::string _to_string(Iterator first, Iterator last)
{
  std::ostringstream strm; 
  while ( first != last )
  {
    strm << *first++;
    if ( first != last ) strm << ',';
  }
  return strm.str();    
}

template<class Iterator>
std::string to_string(Iterator first, Iterator last)
{
  std::ostringstream strm; 
  strm << '<' << _to_string(first,last) << '>';
  return strm.str();
}

template<class Iterator>
std::string to_string(Iterator first, Iterator middle, Iterator last)
{
  std::ostringstream strm; 
  strm << '<' << _to_string(first,middle) 
       << '|' << _to_string(middle,last) << '>';
  return strm.str();
}

template<class Iterator>
std::string to_string(Iterator first, Iterator lower, Iterator upper, Iterator last)
{
  std::ostringstream strm; 
  strm << '<' << _to_string(first,lower)
       << '(' << _to_string(lower,upper) << ')'
       << _to_string(upper,last) << '>';
  return strm.str();
}

template<class Iterator>
inline std::string to_string(Iterator first, std::pair<Iterator,Iterator> middle, Iterator last)
{
  return to_string(first,middle.first,middle.second,last);
}

}

#endif // __TO_STRING_H__
