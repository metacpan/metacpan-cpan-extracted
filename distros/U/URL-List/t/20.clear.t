use Test::More;

use URL::List;

my @urls = (
    'http://www.vg.no',
    'http://www.vg.no:80',
    'http://www.vg.no/',
    'http://www.vg.no:80/',
    'http://www.vg.no/index.html',

    'http://www.vg.no',
    'http://www.vg.no:80',
    'http://www.vg.no/',
    'http://www.vg.no:80/',
    'http://www.vg.no/index.html',
);

my $list = URL::List->new;

#
# clear()
#
foreach my $url ( @urls ) {
    $list->add( $url );
}

is( $list->count, 5, 'URL count is OK' );

$list->clear;

is( $list->count, 0, 'URL count is OK' );

#
# flush()
#
foreach my $url ( @urls ) {
    $list->add( $url );
}

is( $list->count, 5, 'URL count is OK' );

$list->flush;

is( $list->count, 0, 'URL count is OK' );

done_testing;