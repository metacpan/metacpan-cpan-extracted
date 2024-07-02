# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage RequireEndWithOne)
use 5.020;
use strict;
use warnings;
use utf8;
use English qw( -no_match_vars );
use Test2::Bundle::More;
use Test2::Require::Module 'Test::Dependencies';
use Test2::Todo;

our $VERSION = v1.1.6;

if ( not $ENV{'AUTHOR_TESTING'} ) {
## no critic (RequireInterpolationOfMetachars)
    my $msg = q<Set $ENV{AUTHOR_TESTING} to run author tests.>;
    Test2::Bundle::More::skip_all $msg;
}

use Test::Dependencies
  'exclude' => [qw/ WWW::Wookie /],
  'style'   => q{heavy};

my $todo = Test2::Todo->new( 'reason' =>
      q{Test::Dependencies can't do WWW::Wookie::Connector::Service} );
Test::Dependencies::ok_dependencies();
$todo->end;
