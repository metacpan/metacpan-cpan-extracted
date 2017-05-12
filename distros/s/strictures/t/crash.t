use strict;
use warnings FATAL => 'all';
use Test::More
  $] < 5.008004 ? ( skip_all => "can't test extra loading on perl < 5.8.4" )
                : ( tests => 1 );
use File::Spec;

my %extras = map { my $m = "$_.pm"; $m =~ s{::}{/}g; $m => 1 } qw(
  indirect
  multidimensional
  bareword::filehandles
);

unshift @INC, sub {
  my $mod = $_[1];
  die "Can't locate $mod in \@INC\n"
    if $extras{$mod};
  return 0;
};

my $err = do {
  local $ENV{PERL_STRICTURES_EXTRA} = 1;
  local *STDERR;
  open STDERR, '>', File::Spec->devnull;
  eval q{use strictures;};
  $@;
};

is $err, '', 'can manage to survive with some modules missing!';
