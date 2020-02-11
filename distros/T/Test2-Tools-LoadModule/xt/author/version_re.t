package main;

use 5.008001;

use strict;
use warnings;

use Test2::V0 -target => 'Test2::Tools::LoadModule';
use Test2::Tools::LoadModule;

BEGIN {
    $] ge '5.013006'
	or plan skip_all => 'This test requires at least Perl 5.13.6.';
}

# Produced by tools/version_regex -dump
my $VAR1 = qr/ undef | (?^x:
	v (?^:[0-9]+) (?: (?^:\.[0-9]+)+ (?^:_[0-9]+)? )?
	|
	(?^:[0-9]+)? (?^:\.[0-9]+){2,} (?^:_[0-9]+)?
    ) | (?^x: (?^:[0-9]+) (?: (?^:\.[0-9]+) | \. )? (?^:_[0-9]+)?
	|
	(?^:\.[0-9]+) (?^:_[0-9]+)?
    ) /x;

if ( load_module_ok( 'version::regex' ) ) {
    no warnings qw{ once };
    is $version::regex::LAX, $VAR1,
	'$version::regex::LAX has not changed since it was last recorded';
}

done_testing;

1;

# ex: set textwidth=72 :
