#!/usr/bin/perl
#
# This file is part of Test-Pod-LinkCheck
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;

use Test::More;
use Test::Pod::LinkCheck;

plan tests => 4;

my $t = Test::Pod::LinkCheck->new;

# simulate some backend caching tests
is( $t->_backend_err, 0, "Testing _backend_err" );
is( exists $t->_cache->{'cpan'}{'FOO'} ? 1 : 0, 0, "Testing CPAN cache" );
$t->_cache->{'cpan'}{'FOO'} = 1;
$t->_backend_err( 0 );
is( exists $t->_cache->{'cpan'}{'FOO'} ? 1 : 0, 1, "Testing CPAN cache after _backend_err(0)" );
$t->_backend_err( 1 );
is( exists $t->_cache->{'cpan'}{'FOO'} ? 1 : 0, 0, "Testing CPAN cache after _backend_err(1)" );
