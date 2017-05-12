# Copyright (C) 2007 by Peter Pentchev
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.8 or,
# at your option, any later version of Perl 5 you may have available.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl WWW-Domain-Registry-Joker-coverage.t'

BEGIN {
        eval 'use Test::Pod::Coverage tests => 3';
        if ($@) {
                use Test;
                plan tests => 1;
                skip('Test::Pod::Coverage not found');
                exit(0);
        }
}


pod_coverage_ok('WWW::Domain::Registry::Joker');
pod_coverage_ok('WWW::Domain::Registry::Joker::Loggish');
pod_coverage_ok('WWW::Domain::Registry::Joker::Response');
