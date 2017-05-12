#!perl -Tw
use strict;
use Test::More;
use lib "t";

plan tests => 11;

use_ok( "relative" );

# load modules and create aliases from Enterprise::Framework
my $loaded = eval { import relative -to => "Enterprise::Framework" => -aliased => qw(Factory Base) };
is( $@, "", "load modules and create aliases" );

# check that the aliases were created
can_ok( __PACKAGE__, "Base", "Factory" );

can_ok( $loaded, qw(new) );
my $obj = eval { Base()->new() };
is( $@, "", "calling Base()->new()" );
isa_ok( $obj, $loaded, "checking that \$obj" );


# load modules and create aliases from BigApp
$loaded = eval { import relative -to => "BigApp" => -aliased => qw(Report::Publish Report::Create) };
is( $@, "", "load modules and create aliases" );

# check that the aliases were created
can_ok( __PACKAGE__, "Create", "Publish" );

can_ok( $loaded, qw(new_report) );
my $report = eval { Create()->new_report() };
is( $@, "", "calling Create()->new_report()" );
isa_ok( $report, $loaded, "checking that \$report" );
