use Test;
use XML::Generator::Essex;
use XML::SAX::Writer;
use strict;

my $out;
my $w = XML::SAX::Writer->new( Output => \$out );
my $g = XML::Generator::Essex->new( Handler => $w );

my @tests = (
sub {
    $g->set_main( sub {
        put start "foo";
        put "b", chars( "ar" );
        put end;
    } );
    ok 1;
},

sub {
    $g->execute;
    ok $out, qr{<foo\s*>bar</foo>\z};
},
);

plan tests => 0+@tests;

$_->() for @tests;
