# https://github.com/Perl/perl5/commit/d62dd48c3ee7e6e5cee9d356fc1874492bbd930b
use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT is is_deeply ok use_ok ) ], tests => 15;

use Getopt::Std qw( getopts );

my $class;

BEGIN {
  $class = 'Tie::Hash::MultiValueOpts';
  use_ok $class or BAIL_OUT "Cannot load class '$class'!"
}

our ( $opt_f, $opt_i, $opt_o, $opt_x, $opt_y ); ## no critic ( ProhibitPackageVars )

# Then we try the getopts
$opt_o = $opt_i = $opt_f = undef;
local @ARGV = qw( -foi -i file );

ok( getopts( 'oif:' ), 'getopts succeeded (1)' );
is( "@ARGV", 'file', 'options removed from @ARGV (3)' );
ok( $opt_i && $opt_f eq 'oi', 'options -i and -f correctly set' );
ok( !defined $opt_o,          'option -o not set' );

tie my %opts, 'Tie::Hash::MultiValueOpts';
$opt_i = undef;
local @ARGV = qw( -hij -k -- -l m );

ok( getopts( 'hi:kl', \%opts ), 'getopts succeeded (2)' );
is( "@ARGV", '-l m', 'options removed from @ARGV (4)' );
ok( $opts{ h } && $opts{ k }, 'options -h and -k set' );
is( $opts{ i }, 'j', q/option -i is 'j'/ );
ok( !defined $opt_i, '$opt_i still undefined' );

# Try illegal options, but avoid printing of the error message
my $warning;
local $SIG{ __WARN__ } = sub { $warning = $_[ 0 ] };
local @ARGV = qw( -h help );

ok( !getopts( 'xf:y' ),                'getopts fails for an illegal option' );
ok( $warning eq "Unknown option: h\n", 'user warned' );

undef %opts;
my $expected;
{
  local @ARGV = qw( -a -b foo -c );
  # https://github.com/Perl/perl5/issues/23906
  # Getopt::Std questionable undefined value bahaviour
  getopts( 'ab:c:', \%opts );
  $expected = { 'a' => 1, 'b' => 'foo', 'c' => undef };
  is_deeply( \%opts, $expected, 'getopts: multiple switches; switch expected argument, none provided; value undef' );
  undef %opts;
}

{
  local @ARGV = qw( -c );
  getopts( 'c:', \%opts );
  $expected = { 'c' => undef };
  is_deeply( \%opts, $expected, 'getopts: single switch; switch expected argument, none provided; value undef' );
  undef %opts;
}

{
  local @ARGV = qw( -a -b foo -c );
  getopts( 'ab:c:', \my %opts );
  $expected = { 'a' => 1, 'b' => 'foo', 'c' => undef };
  is_deeply( \%opts, $expected,
    'getopts (scoped): multiple switches; switch expected argument, none provided; value undef' );
  undef %opts;
}
