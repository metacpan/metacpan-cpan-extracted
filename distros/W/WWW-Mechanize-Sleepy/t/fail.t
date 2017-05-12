use Test::More tests => 5; 
use strict;
use warnings;

use_ok( 'WWW::Mechanize::Sleepy' );

eval { my $a = WWW::Mechanize::Sleepy->new( sleep => 'three' ); };
like( $@, qr/sleep parameter must be an integer or a range i1..i2/, 
    'new() non int/range sleep' );

eval { my $a = WWW::Mechanize::Sleepy->new( sleep => '5..2' ); };
like( $@, qr/sleep range \(i1..i2\) must have i1 < i2/,, 
    'new() n2 greater than n1 in range' );

eval { 
    my $a = WWW::Mechanize::Sleepy->new();
    $a->sleep( 'three' );
};
like( $@, qr/sleep parameter must be an integer or a range i1..i2/, 
    'sleep() non int/range sleep' );

eval { 
    my $a = WWW::Mechanize::Sleepy->new();
    $a->sleep( '5..2' );
};
like( $@, qr/sleep range \(i1..i2\) must have i1 < i2/,, 
    'sleep() n2 greater than n1 in range' );

