use strict;
use warnings;

use Test::More;
use File::Spec;
use XS::TCC qw(:all);

my $data_dir = -d 't' ? File::Spec->catdir(qw(t data)) : 'data';

tcc_inline <<HERE;
HERE

pass("Alive");

tcc_inline
  typemap => ExtUtils::Typemaps->new,
  q{
  };

pass("Alive after compilation");

################################################################################

tcc_inline
  #warn_code => 1,
  q{
    int foo(int bar) {
      return bar * 2;
    }
  };

pass("Alive after compilation");

is(main::foo(3), 6, "Simple function is callable");

pass("Alive");

################################################################################

tcc_inline
  #warn_code => 1,
  q{
    AV *
    pairwise_sum (AV *left, AV *right)
    {
      size_t i;
      SV **elem;
      double val = 0;
      const size_t len_left  = av_len(left)+1;
      const size_t len_right = av_len(right)+1;
      const size_t len = len_left < len_right ? len_left : len_right;
      AV *retval = newAV();
      sv_2mortal((SV *)retval);
      av_extend(retval, len-1);
      for (i = 0; i < len; ++i) {
        val = 0;
        elem = av_fetch(left, i, 0);
        if (elem != NULL)
          val += SvNV(*elem);
        elem = av_fetch(right, i, 0);
        if (elem != NULL)
          val += SvNV(*elem);
        av_store(retval, i, newSVnv(val));
      }
      return retval;
    }
    int foo2(int bar) {
      return bar * 2;
    }
  };

pass("Alive after compilation");

is(foo2(2), 4, "Simple function wrapped as part of multi-function wrapper");

pass("Alive");

is_deeply(pairwise_sum([1..10], [1..9]), [map $_*2, 1..9], "pairwise sum wrapped ok");

pass("Alive");

################################################################################

tcc_inline
  #warn_code => 1,
  q{
    SV *
    foo3(pTHX_ SV *sv)
    {
      return sv_2mortal(newSViv(SvIV(sv)+1));
    }
  };

pass("Alive after compilation");

is(foo3(5), 6, "simple function with pTHX works");

pass("Alive");

################################################################################

tcc_inline
  add_files => File::Spec->catfile($data_dir, 'inctest.c'),
  q{
    int wrapper(int input) {
      return mydbl(input);
    }
  };

pass("Alive after compilation (add_file inctest.c)");

is(wrapper(5), 10, "add_files works for C file");

pass("Alive");

################################################################################

tcc_inline
  #warn_code => 1,
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

pass("Alive after compilation");

SCOPE: {
  my $s = main::which_context();
  ok(defined($s), "pTHX works");

  $s = main::which_context_slow();
  ok(defined($s), "dTHX works (testing code from docs)");
}

pass("Alive");

################################################################################

tcc_inline
  #warn_code => 1,
  q{
    int get_underbar_sum(pTHX_ int bar) {
      dUNDERBAR;
      return (int)SvIV(UNDERBAR) + bar;
    }
  };

pass("Alive after compilation");

SCOPE: {
  local $_ = 42;
  is(main::get_underbar_sum(12), 42+12, "pTHX_ works");
}

pass("Alive");

################################################################################

done_testing();
