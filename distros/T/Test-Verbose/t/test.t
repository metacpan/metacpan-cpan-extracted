use strict;

use Test;

use Test::Verbose;

use Fatal qw( chdir );


my @tests = (
sub {
    chdir "t/pretend";
    ok join( ",", Test::Verbose->new->test_scripts_for( "lib" ) ),
        "t/bar.t,t/bat.t,t/baz.t,t/foo.t";
},

sub {
    ok join( ",", Test::Verbose->new->test_scripts_for( "t" ) ),
        "t/bar.t,t/bat.t,t/baz.t,t/foo.t";
},

sub {
    ok join( ",", Test::Verbose->new->test_scripts_for( reverse glob "t/*.t" ) ),
        "t/bar.t,t/bat.t,t/baz.t,t/foo.t";
},
sub {
    chdir "lib";
    ok join( ",", Test::Verbose->new->test_scripts_for( "Foo.pm" ) ),
        "t/bar.t,t/bat.t,t/baz.t,t/foo.t";
},

sub {
    ok join( ",", Test::Verbose->new->test_scripts_for( "Foo" ) ),
        "t/bar.t,t/baz.t,t/foo.t";
},

sub {
    ok join( ",", Test::Verbose->new->test_scripts_for( "gorp.t" ) ),
        "t/gorp.t";
},

);

plan tests => 0+@tests;

$_->() for @tests;

