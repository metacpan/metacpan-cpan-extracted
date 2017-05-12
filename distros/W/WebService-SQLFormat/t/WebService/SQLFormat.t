use strict;
use warnings;

use Test::RequiresInternet( 'sqlformat.org' => 80 );
use Test2::Bundle::More;

use WebService::SQLFormat;

my $f = WebService::SQLFormat->new( debug_level => $ENV{AUTHOR_TESTING}
        && !$ENV{TRAVIS} ? 11 : 0, reindent => 1, );
ok( $f, 'formatter compiles' );

ok( $f->url, 'url: ' . $f->url );

my $got      = $f->format_sql('selecT * from foo');
my $expected = qq{selecT *\nfrom foo};

is( $got, $expected, 'formats as expected' );

done_testing();
