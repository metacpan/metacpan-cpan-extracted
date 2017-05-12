use strict;

use Test;
use XML::SAX::Machines qw( Machine Tap );

my $m;

my $tap_out;
my $main_out;

my @tests = (
sub {
    $m = Machine(
        [ Intake => Tap( "XML::SAX::Base", \$tap_out ) => qw( B ) ],
        [ B      => "XML::SAX::Base"                   => qw( C ) ],
        [ C      => \$main_out                                    ],
    );
    ok $m->isa( "XML::SAX::Machine" );
},

sub {
    $m->parse_string( "<foo><bar /></foo>" );
    ok 1;
},

sub {
    $tap_out =~ m{<foo\s*><bar\s*/></foo\s*>}
        ? ok 1
        : ok $tap_out, "something like <foo><bar /></foo>", "tap_out" ;
},

sub {
    $main_out =~ m{<foo\s*><bar\s*/></foo\s*>}
        ? ok 1
        : ok $main_out, "something like <foo><bar /></foo>", "main_out" ;
},
);

plan tests => scalar @tests;

$_->() for @tests;
