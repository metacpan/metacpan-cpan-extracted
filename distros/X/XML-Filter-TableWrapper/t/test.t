use strict;

use Test;
use XML::SAX::PurePerl;
use XML::Filter::TableWrapper;
use XML::SAX::Writer;
use UNIVERSAL;

my $p;
my $h;
my $w;

my $out;

sub _tr { "<tr>" . ( "<td />" x shift ) . "</tr>" }
sub _table { "<table>" . shift() . "</table>" }

sub _re($) {
    my $re = shift;
    $re =~ s{(/?>)}{\\s*$1}g;
    $re =~ s/ /\\s*/g;
    return qr/$re/;
}

sub _ok {
    my $expected = shift;
    ( my $input = $expected ) =~ s/<.?tr\s*>//g;
    $out = "";
    $p->parse_string( $input );
    @_ = $out =~ _re $expected
        ? ( 1 )
        : ( "this output:   $out", "something like $expected" );
    goto &ok;
}

my @tests = (
sub {
    $w = XML::SAX::Writer->new( Output => \$out );
    $h = XML::Filter::TableWrapper->new( Handler => $w );
    $p = XML::SAX::PurePerl->new( Handler => $h );
    ok 1;
},

sub { _ok _table _tr( 4 ) },
sub { _ok _table _tr( 5 ) },
sub { _ok _table _tr( 5 ) . _tr( 1 ) },
sub { _ok _table _tr( 5 ) . _tr( 5 ) . _tr( 3 ) },

sub {
    $h->Columns( 3 );
    _ok _table _tr( 3 ) . _tr( 2 );
},

);

plan tests => scalar @tests;

$_->() for @tests;


