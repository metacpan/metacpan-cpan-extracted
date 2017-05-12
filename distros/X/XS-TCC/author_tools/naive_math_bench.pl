use 5.012;
use warnings;
use blib;

# $ perl author_tools/naive_math_bench.pl
#                  Rate   perl    tcc
# perl 654.785+-0.029/s     -- -90.9%
# tcc  7167.74+-0.022/s 994.7%     --

use Benchmark::Dumb qw(cmpthese);
use XS::TCC qw(tcc_inline);

tcc_inline
  typemap => "const int    T_IV",
  q{
    double tcc_math(const int n) {
      int i, j;
      double res = 0;
      for (i = 0; i < n; ++i) {
        for (j = 0; j < n; ++j)
          res += i / (double)(j == 0 ? 1 : j);
      }
      return res;
    }
  };

sub perl_math {
  my $n = shift;
  --$n;
  my $res = 0;
  for my $i (0..$n) {
    $res += $i / ($_ == 0 ? 1 : $_) for 0..$n;
  }
  return $res;
}

cmpthese(1000.001, {
  tcc  => '::tcc_math(100)',
  perl => '::perl_math(100)',
});

