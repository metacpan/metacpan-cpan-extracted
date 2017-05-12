#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;
use Util::Utl;

is( utl->first( sub { defined }, ( undef, undef, qw/ 1 2 3 /, undef ) ), 1 );

my ( %hash, @result );

%hash = qw/ a 1 b 2 c 3 d 4 /;
is( utl->first( \%hash, qw/ a b c d / ), 1 );
is( utl->first( \%hash, qw/ d c b a / ), 4 );
throws_ok { utl->first( \%hash, qw/ d c b a /, { exclusive => 1 } ) } qr/\Qfirst: Found non-exclusive keys (d c b a) in hash\E/;
is( utl->first( \%hash, qw/ c e /, { exclusive => 1 } ), 3 );
throws_ok { utl->first( \%hash, qw/ b e a /, { exclusive => 1 } ) } qr/\Qfirst: Found non-exclusive keys (b a) in hash\E/;

%hash = ( a => undef, b => '', c => 1 );
is( utl->first( \%hash, qw/ a b c /, { test => sub { defined } } ), '' ); 
is( utl->first( \%hash, qw/ a b c /, { test => sub { ! utl->empty( $_ ) } } ), 1 ); 

warning_is { is( utl->first( \%hash, qw/ x y z / ), undef ) } '';
is( @result = utl->first( \%hash, qw/ x y z / ), 1 );
is( @result = utl->first( \%hash, qw/ x y z /, { empty => 1 } ), 0 );

done_testing;

1;
