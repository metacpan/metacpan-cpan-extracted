#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;
use Util::Utl;

ok( utl->empty( undef ) );
ok( utl->empty( '' ) );
ok( !utl->empty( ' ' ) );

done_testing;
