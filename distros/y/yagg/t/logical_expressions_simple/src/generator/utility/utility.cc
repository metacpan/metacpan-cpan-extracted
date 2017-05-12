#include <cstdlib>
#include <iostream>
#include <list>

#ifdef __GNUC__
#include <cxxabi.h>
#endif // __GNUC__

using namespace std;

#include "generator/utility/utility.h"
#include "generator/rule_list/rule_list.h"
#include "generator/rule/rule.h"

string Utility::indent;

#ifdef SHORT_RULE_TRACE
void Utility::Indent()
{
  indent += "|";
}

void Utility::Unindent()
{
  assert(indent.size() != 0);
  indent.erase(indent.size()-1,indent.size());
}

std::string Utility::to_string(const Rule_List &in_rule_list, const bool &in_show_lengths)
{
  std::ostringstream strm;

  strm << indent;

  strm << "<";

  Rule_List::const_iterator a_rule;
  for(a_rule = in_rule_list.begin(); a_rule != in_rule_list.end(); a_rule++)
  {
    if (a_rule != in_rule_list.begin())
      strm << ',';
    strm << Utility::readable_type_name(typeid(**a_rule));
    if (in_show_lengths)
      strm << "(" << (*a_rule)->Get_Allowed_Length() << ")";
  }

  strm << ">" << endl;

  return strm.str();
}
#endif // SHORT_RULE_TRACE

// ---------------------------------------------------------------------------

void Utility::yyerror()
{
  Rule_List::CURRENTLY_ACTIVE_RULE_LIST->m_error_occurred = true;
}


// ---------------------------------------------------------------------------

// http://groups.google.com/groups?selm=864r9utmlv.fsf%40Zorthluthik.foo

#ifdef __GNUC__

string Utility::readable_type_name(type_info const& typeinfo)
{
  int status;
  char* name= abi::__cxa_demangle(typeinfo.name(),0,0,&status);
  if (name)
  {
    string ret(name);
    free(name);
    return ret;
  }
  string ret;
  switch (status)
  {
    case 0:
      ret = "error code = 0: success";
      break;
    case -1:
      ret = "error code = -1: memory allocation failure";
      break;
    case -2:
      ret = "error code = -2: invalid mangled name";
      break;
    case -3:
      ret = "error code = -3: invalid arguments";
      break;
    default:
      ret = "error code unknown - who knows what happened";
  } return ret;
}

#else // __GNUC__

string Utility::readable_type_name(type_info const& typeinfo)
{
  return typeinfo.name();
}

#endif // __GNUC__
