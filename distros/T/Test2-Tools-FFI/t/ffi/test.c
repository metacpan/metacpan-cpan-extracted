#include <t2t/simple.h>

int
myanswer()
{
  return 42;
}

void
test_simple_diagnostics()
{
  note("this is debug information, may not be critical");
  /* this line is bad luck */
  diag("this is IMPORTANT, make sure we see it");
}

void
test_format_diagnostics()
{
  notef("note number = %d", 42);
  diagf("diag number = %d", 47);
}

void test_simple_passfail()
{
  pass("this is a passing test");
  fail("this is a failing test");
}

