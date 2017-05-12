#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
plan tests => 3;

BEGIN {
    use_ok('Mojo::Base');
    use_ok('Mojo::UserAgent');
    use_ok('WebService::Rollbar::Notifier') || print "Bail out!\n";
}
diag( 'Testing WebService::Rollbar::Notifier'
    . " $WebService::Rollbar::Notifier::VERSION, Perl $], $^X" );