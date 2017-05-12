use strict;

use Test;
use XML::SAX::Machines qw( Machine );
use lib qw( t/lib );

my $m;

my $out1;
my $out2;
my $out3;

my @tests = (
sub {
    $m = Machine(
        [ Intake => "XML::Filter::SAXT" => ( 1, 2, 3  ) ],
        [ undef,    "XML::SAX::Base"    => 4            ],
        [ undef,    "XML::SAX::Base"    => 5            ],
        [ undef,    "XML::SAX::Base"    => 6            ],
        \$out1,
        \$out2,
        \$out3,
    ),
    ok $m->isa( "XML::SAX::Machine" );
},

sub {
    $out1 = "";
    $out2 = "";
    $out3 = "";
    ok $m->parse_string( "<foo><bar /></foo>" );
},

sub {
    $out1 =~ m{<foo\s*><bar\s*/></foo\s*>}
        ? ok 1
        : ok $out1, "out1: something like <foo><bar /></foo>" ;
},

sub {
    $out2 =~ m{<foo\s*><bar\s*/></foo\s*>}
        ? ok 1
        : ok $out2, "out2: something like <foo><bar /></foo>" ;
},

sub {
    $out3 =~ m{<foo\s*><bar\s*/></foo\s*>}
        ? ok 1
        : ok $out3, "out3: something like <foo><bar /></foo>" ;
},

);

plan tests => scalar @tests;

$_->() for @tests;
