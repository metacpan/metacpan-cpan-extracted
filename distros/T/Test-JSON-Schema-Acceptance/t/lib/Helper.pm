# vim: set ft=perl ts=8 sts=2 sw=2 tw=100 et :
# no package, so things defined here appear in the namespace of the parent.
use strictures 2;
use 5.020;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
no if "$]" >= 5.041009, feature => 'smartmatch';
no feature 'switch';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::Deep qw(!array !hash !blessed); # import symbols: ignore, re etc
use Test2::API 'context_do';

my $encoder = JSON::PP->new->allow_nonref(1)->utf8(0)->allow_blessed(1)->allow_bignum(1)->canonical(1)->convert_blessed(1)->pretty(1)->space_before(0);

# deep comparison, with Test::Deep syntax sugar
sub cmp_result ($got, $expected, $test_name) {
  context_do {
    my $ctx = shift;
    my ($got, $expected, $test_name) = @_;
    my ($equal, $stack) = Test::Deep::cmp_details($got, $expected);
    if ($equal) {
      $ctx->pass($test_name);
    }
    else {
      $ctx->fail($test_name);
      my $method =
        # be less noisy for expected failures
        (grep $_->{todo}, Test2::API::test2_stack->top->{_pre_filters}->@*) ? 'note'
          : $ENV{AUTHOR_TESTING} || $ENV{AUTOMATED_TESTING} ? 'diag' : 'note';
      $ctx->$method(Test::Deep::deep_diag($stack));
      $ctx->$method("got result:\n".$encoder->encode($got));
    }
    return $equal;
  } $got, $expected, $test_name;
}

sub failing_test_names ($events) {
  my $sub = sub (@events) {
    map +(
      ($_->{pass}//1) ? () : (
        $_->{name},
        $_->{subevents}
          ? (map +('  '.$_), __SUB__->($_->{subevents}->@*))
          : (),
      )
    ),
    @events
  };

  $sub->($events->flatten(args => [ include_subevents => 1 ])->@*);
}

1;
