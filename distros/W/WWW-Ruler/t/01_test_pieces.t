use strict;
use warnings;

use Test::More tests => 21;

use WWW::Ruler;

my $ruler = WWW::Ruler->new( page_size => 5, ruler_size => 12, amount => 13 );

my $piece;

$piece = $ruler->cut_off( page_number => 1 );

ok( ref $piece->ruler eq 'ARRAY' && @{ $piece->ruler } > 0 );
ok( ! $piece->outside );
ok( $piece->start == 0 );
ok( $piece->end == 4 );

$piece = $ruler->cut_off( page_number => 2 );

ok( ref $piece->ruler eq 'ARRAY' && @{ $piece->ruler } > 0 );
ok( ! $piece->outside );
ok( $piece->start == 5 );
ok( $piece->end == 9 );

$piece = $ruler->cut_off( page_number => 3 );

ok( ref $piece->ruler eq 'ARRAY' && @{ $piece->ruler } > 0 );
ok( ! $piece->outside );
ok( $piece->start == 10 );
ok( $piece->end == 12 );

$piece = $ruler->cut_off( page_number => 4 );

ok( ref $piece->ruler eq 'ARRAY' && @{ $piece->ruler } == 0 );
ok( $piece->outside );
ok( $piece->start == 0 && $piece->end == 0 );

$piece = $ruler->cut_off( page_number => 0 );

ok( ref $piece->ruler eq 'ARRAY' && @{ $piece->ruler } == 0 );
ok( $piece->outside );
ok( $piece->start == 0 && $piece->end == 0 );

$piece = $ruler->cut_off( page_number => -1 );

ok( ref $piece->ruler eq 'ARRAY' && @{ $piece->ruler } == 0 );
ok( $piece->outside );
ok( $piece->start == 0 && $piece->end == 0 );
