#!/usr/bin/perl

use strict;
use Test::More tests => 8;
use URPM;

my $u = URPM->new;

eval { $u->parse_hdlist('non-existent'); };
like( $@, qr/^cannot open hdlist file non-existent/, 'fatal error on hdlist not found' );
is( $! + 0, $!{EBADF}, '$! is EBADF' );
eval { $u->parse_synthesis('non-existent'); };
like( $@, qr/^unable to read synthesis file non-existent/, 'fatal error on synthesis not found' );
is( $! + 0, $!{ENOENT}, '$! is ENOENT' );

my $v = URPM->new( nofatal => 1 );

eval { $v->parse_hdlist('non-existent'); };
is( $@, '', 'no error on hdlist not found' );
is( $! + 0, $!{EBADF}, '$! is EBADF' );
eval { $v->parse_synthesis('non-existent'); };
is( $@, '', 'no error on synthesis not found' );
is( $! + 0, $!{ENOENT}, '$! is ENOENT' );
