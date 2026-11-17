#
#===============================================================================
#
#  DESCRIPTION:  How the value returned by a source subroutine is
#                normalised before it is cached, and what "clone" does to
#                each shape of data.
#
#       AUTHOR:  Anton Morozov (antonfin@cpan.org)
#===============================================================================

use strict;
use warnings;
use lib 'blib/lib';

use Test::More tests => 8;

use_ok('Tie::Cache::Autoupdater');

tie my %cache, 'Tie::Cache::Autoupdater',
    nothing      => { timeout => 60, source => sub { return } },
    undefined    => { timeout => 60, source => sub { return undef } },
    single       => { timeout => 60, source => sub { return 'one value' } },
    several      => { timeout => 60, source => sub { return ( 1, 2, 3 ) } },
    reference    => { timeout => 60, source => sub { return { a => 1 } } },
    plain_clone  => { timeout => 60, clone => 1, source => sub { return 'scalar' } },
    nested_clone => { timeout => 60, clone => 1, source => sub { return { list => [ 1, 2 ] } } };

is ( $cache{nothing}, undef,
    'a source returning an empty list caches undef' );
is ( $cache{undefined}, undef,
    'an explicit undef is a single value, and caches undef too' );
is ( $cache{single}, 'one value',
    'a single value is cached as it is' );
is_deeply ( $cache{several}, [ 1, 2, 3 ],
    'two or more values are cached as an array reference' );
is_deeply ( $cache{reference}, { a => 1 },
    'a single reference is cached without being wrapped' );
is ( $cache{plain_clone}, 'scalar',
    'clone leaves a plain scalar alone' );

my $nested = $cache{nested_clone};
$nested->{list}[0] = 99;
is_deeply ( $cache{nested_clone}, { list => [ 1, 2 ] },
    'clone copies nested data too, so a deep change cannot reach the cache' );

1;

