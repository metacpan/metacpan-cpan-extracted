use strict;
use warnings;

use Benchmark::Dumb qw(cmpthese);
use File::Spec;
use XS::TCC qw(:all);

my $data_dir = -d 't' ? File::Spec->catdir(qw(t data)) : 'data';

tcc_inline
  q{
  /* efficient */
  int which_context(pTHX) {
    return (int)GIMME_V;
  }

  /* less efficient */
  int which_context_slow() {
    dTHX;
    return (int)GIMME_V;
  }
  };

cmpthese(
  10000,
  {
    dTHX => sub { which_context_slow() for 1..1000; },
    pTHX => sub { which_context() for 1..1000; },
  }
);

