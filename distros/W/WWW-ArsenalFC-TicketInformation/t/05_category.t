#!perl

use strict;
use warnings;

use Test::More tests => 6;

BEGIN { use_ok('WWW::ArsenalFC::TicketInformation::Category'); }

my $category = new_ok(
    'WWW::ArsenalFC::TicketInformation::Category',
    [
        category    => 'C',
        date_string => 'Saturday, August 18',
    ]
);

is( $category->category,    'C' );
is( $category->date_string, 'Saturday, August 18' );

# test date()
is( $category->date, '2012-08-18' );
$category->{date_string} = 'Saturday December 1';
is( $category->date, '2012-12-01' );
