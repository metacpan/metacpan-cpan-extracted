#!/usr/bin/perl -Tw

BEGIN {
    if ( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}

use strict;

use Test::More tests => 2;

BEGIN {
    use_ok( 'Test::Run::Obj' );
}

my $obj = Test::Run::Obj->new();
my $strap = $obj->Strap();
isa_ok( $strap, 'Test::Run::Straps' );

