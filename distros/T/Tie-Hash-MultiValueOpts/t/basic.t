use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT is is_deeply ok use_ok ) ], tests => 14;

use Getopt::Std qw( getopts );

my $class;

BEGIN {
  $class = 'Tie::Hash::MultiValueOpts';
  use_ok $class or BAIL_OUT "Cannot load class '$class'!"
}

tie my %opts, 'Tie::Hash::MultiValueOpts';
$opts{ l } = [];

local @ARGV = ();
ok getopts( 'a:bl:', \%opts ), 'Successful execution';
ok not( exists $opts{ a } ),   'Option "a" has no argument'; ## no critic ( RequireTestLabels )
ok not( exists $opts{ b } ),   'Flag "b" is not set (false)'; ## no critic ( RequireTestLabels )
is_deeply $opts{ l }, [], 'Option "l" refers to an empty list';

is_deeply \%opts, { l => [] }, '"%opts" has registered "l" option only';
local @ARGV = qw( -a foo -b -l bar -a quux -l baz ); ## no critic ( RequireLocalizedPunctuationVars )
ok getopts( 'a:bl:', \%opts ), 'Successful execution';
is $opts{ a }, 'quux', 'Option "a" has an argument (overwrite)';
ok $opts{ b }, 'Flag "b" is set (true)';
is_deeply $opts{ l }, [ qw( bar baz ) ], 'Option "l" refers to a list with 2 elements';

%opts = ();
$opts{ l } = [];
local @ARGV = qw( -a foo -b -l bar -a quux -l baz -l ); ## no critic ( RequireLocalizedPunctuationVars )
ok !getopts( 'a:bl:', \%opts ), 'Failed execution (no argument provided for last "l" option use)';
is $opts{ a }, 'quux', 'Option "a" has an argument (overwrite)';
ok $opts{ b }, 'Flag "b" is set (true)';
is_deeply $opts{ l }, [ qw( bar baz ), undef ], 'Option "l" refers to a list with an undef element'
