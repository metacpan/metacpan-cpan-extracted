#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;
use Util::Utl;

ok( utl->blank( undef ) );
ok( utl->blank( '' ) );
ok( utl->blank( ' ' ) );
ok( utl->blank( "\n" ) );
ok( !utl->blank( '-' ) );

done_testing;
