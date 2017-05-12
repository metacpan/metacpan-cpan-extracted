use strict;
use warnings;

use Test::More;
use XS::TCC;
use File::Spec;

pass("Alive");

SCOPE: {
  my $comp = XS::TCC::TCCState->new;
  isa_ok($comp, "XS::TCC::TCCState");
}

pass("Alive");

sub make_comp {
  my $comp = XS::TCC::TCCState->new;
  $comp->add_sysinclude_path($XS::TCC::RuntimeIncludeDir);
  return $comp;
}
SCOPE: {
  my $comp = make_comp();
  my $i = $comp->compile_string("");
  is($i, 0);

  is($comp->compile_string(<<'HERE'), 0, "Real code example compiles");
int
xs_tcc_test_foo(int a, int b)
{
  return a + b;
}
HERE
  is($comp->relocate(), 0);
  isa_ok($comp->get_symbol("xs_tcc_test_foo"), "XS::TCC::TCCSymbol");
}

SCOPE: {
  my $comp = make_comp();
  $comp->set_options($XS::TCC::CCOPTS);
  if ($^O eq 'darwin') {
    $comp->define_symbol("__XS_TCC_DARWIN__", 1);
  }

  is($comp->compile_string(<<'HERE'), 0, "Real XS example compiles");
#ifdef __XS_TCC_DARWIN__
/* http://comments.gmane.org/gmane.comp.compilers.tinycc.devel/325 */
typedef unsigned short __uint16_t, uint16_t;
typedef unsigned int __uint32_t, uint32_t;
typedef unsigned long __uint64_t, uint64_t;
#endif

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#ifdef HAS_BUILTIN_EXPECT
#  undef HAS_BUILTIN_EXPECT
#  ifdef EXPECT
#    undef EXPECT
#    define EXPECT(expr, val) (expr)
#  endif
#endif

void
xs_tcc_test_bar(pTHX_ CV *cv)
{
  dVAR; dXSARGS; dXSTARG;
  IV rv;

  if (items != 2)
    croak("Need two params");

  rv = SvIV(ST(0)) + SvIV(ST(1));

  { XSprePUSH; PUSHi((IV)rv); }
  XSRETURN(1);
}
HERE

  is($comp->relocate(), 0);
  my $sym = $comp->get_symbol("xs_tcc_test_bar");
  isa_ok($sym, "XS::TCC::TCCSymbol");

  my $sub = $sym->as_xsub();

  ok(!eval {$sub->(); 1} && $@);
  is($sub->(3, 5), 8, "XSUB can add!");
}

pass("Alive");

SCOPE: {
  my $comp = make_comp();
  $comp->set_options($XS::TCC::CCOPTS);
  my $callback_count = 0;
  my $errstr;
  $comp->set_error_callback(sub {
    $errstr = shift;
    $callback_count++;
  });
  
  $comp->compile_string(<<'HERE');
#include <EXTERN.h>
#ifdef HAS_BUILTIN_EXPECT
#  undef HAS_BUILTIN_EXPECT
#  ifdef EXPECT
#    undef EXPECT
#    define EXPECT(expr, val) (expr)
#  endif
#endif
#include <perl.h>
#include <XSUB.h>

void
xs_tcc_test_bar(pTHX_ CV *cv)
{
  this is a compile error
}
HERE

  cmp_ok($callback_count, '>=', 1, "error callback called");
  ok(defined($errstr), "error string defined");
  note("Compile error is: '$errstr'");
}

pass("Alive");

done_testing();
