use Unicode::CaseFold;
use charnames ':full';
use Benchmark 'cmpthese';

my $str = "Wei\N{LATIN SMALL LETTER SHARP S}" x 1000;

cmpthese(-10,
  {
    fc       => sub { my $throwaway = Unicode::CaseFold::fc($str) },
    casefold => sub { my $throwaway = Unicode::CaseFold::case_fold($str) },
    lc       => sub { my $throwaway = lc $str },
  }
);
