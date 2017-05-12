use strict;
use warnings;
use Test::More;
use WorePAN;

plan skip_all => "set WOREPAN_NETWORK_TEST to test" unless $ENV{WOREPAN_NETWORK_TEST};

# CPAN::ParseDistribution accepts regular CPAN distributions only

my %cant_be_included = (

  # ppm archives
  'I/IT/ITUB/ppm/PerlMol-0.35_00.ppm.tar.gz' => 'PerlMol',
  'T/TE/TEVERETT/Data-BitMask-0.90.ppm.zip' => 'Data::BitMask',

  # pm.gz
  'T/TO/TOMC/Simple.pm.gz' => 'Simple',

  # perl itself
  'R/RJ/RJBS/perl-5.16.0.tar.gz' => 'perl',
  'T/TT/TTY/kurila-1.19_0.tar.gz' => 'kurita',

  # other old scripts
  'V/VL/VLADO/text2xfig.pl-1.3' => 'text2xfig',
);

for my $file (keys %cant_be_included) {
  my $worepan = eval {
    WorePAN->new(
      files => [$file],
      no_network => 0,
      use_backpan => 1,
      cleanup => 1,
    );
  };

  ok !$@ && $worepan, "created worepan mirror";
  note $@ if $@;
  ok $worepan && $worepan->file($file)->exists, "downloaded $file successfully";
  ok $worepan && !$worepan->look_for($cant_be_included{$file}), "not found in the index";
}

done_testing;
