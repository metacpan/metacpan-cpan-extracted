#include "model/nonterminal_rules/wfe.h"
#include <cassert>

#include "model/terminal_rules/ATOMIC.h"
#include "model/terminal_rules/BINARY_OPERATOR.h"
#include "model/terminal_rules/LEFT_PAREN.h"
#include "model/terminal_rules/RIGHT_PAREN.h"
#include "model/terminal_rules/UNARY_OPERATOR.h"

#include <list>

using namespace std;

// ---------------------------------------------------------------------------

class wfe::match_1 : public Rule_List
{
  friend class wfe;

  match_1()
  {
    push_back(new wfe);
    push_back(new BINARY_OPERATOR);
    push_back(new wfe);
  }

};

// ---------------------------------------------------------------------------

class wfe::match_2 : public Rule_List
{
  friend class wfe;

  match_2()
  {
    push_back(new LEFT_PAREN);
    push_back(new wfe);
    push_back(new RIGHT_PAREN);
  }

};

// ---------------------------------------------------------------------------

class wfe::match_3 : public Rule_List
{
  friend class wfe;

  match_3()
  {
    push_back(new UNARY_OPERATOR);
    push_back(new wfe);
  }

};

// ---------------------------------------------------------------------------

class wfe::match_4 : public Rule_List
{
  friend class wfe;

  match_4()
  {
    push_back(new ATOMIC);
  }

};

// ---------------------------------------------------------------------------

wfe::wfe() : Nonterminal_Rule()
{
  m_1 = NULL;
  m_2 = NULL;
  m_3 = NULL;
  m_4 = NULL;
}

// ---------------------------------------------------------------------------

wfe::~wfe()
{
  if (m_1 != NULL)
    delete m_1;
  if (m_2 != NULL)
    delete m_2;
  if (m_3 != NULL)
    delete m_3;
  if (m_4 != NULL)
    delete m_4;
}

// ---------------------------------------------------------------------------

void wfe::Initialize(const unsigned int in_allowed_length, const Rule *in_previous_rule)
{
  m_rule_lists.clear();

#ifndef DISABLE_PRODUCTION_LENGTH_OPTIMIZATION
  if (in_allowed_length >= 1)
#endif // DISABLE_PRODUCTION_LENGTH_OPTIMIZATION
  {
    if (m_1 == NULL)
      m_1 = new match_1;

    m_rule_lists.push_back(m_1);
  }

#ifndef DISABLE_PRODUCTION_LENGTH_OPTIMIZATION
  if (in_allowed_length >= 2)
#endif // DISABLE_PRODUCTION_LENGTH_OPTIMIZATION
  {
    if (m_2 == NULL)
      m_2 = new match_2;

    m_rule_lists.push_back(m_2);
  }

#ifndef DISABLE_PRODUCTION_LENGTH_OPTIMIZATION
  if (in_allowed_length >= 1)
#endif // DISABLE_PRODUCTION_LENGTH_OPTIMIZATION
  {
    if (m_3 == NULL)
      m_3 = new match_3;

    m_rule_lists.push_back(m_3);
  }

#ifndef DISABLE_PRODUCTION_LENGTH_OPTIMIZATION
  if (in_allowed_length == 1)
#endif // DISABLE_PRODUCTION_LENGTH_OPTIMIZATION
  {
    if (m_4 == NULL)
      m_4 = new match_4;

    m_rule_lists.push_back(m_4);
  }

  Nonterminal_Rule::Initialize(in_allowed_length, in_previous_rule);
}
