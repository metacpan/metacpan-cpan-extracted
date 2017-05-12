use Test;
use XML::Filter::Mode;
use XML::SAX::Machines qw( Pipeline );
use strict;

my $out;
my $p = Pipeline( "XML::Filter::Mode" => \$out );

my $doc_comma = q{<doc>
  <fooA  mode="A"  ><barA  /></fooA>
  <fooB  mode="B"  ><barB  /></fooB>
  <fooAB mode="A,B"><barAB /></fooAB>
</doc>};

( my $doc_or  = $doc_comma ) =~ s/,/|/g;
( my $doc_and = $doc_comma ) =~ s/,/&amp;/g;

( my $doc_not = $doc_comma ) =~ s/"A/"!A/g;

my @operators = ( ",", "|", "&" );

my @tests = (
map(
    {
        my $doc = $_;
        my $operator = shift @operators;
        (
            sub {
                $p->Intake->modes( "" );
                $p->parse_string( $doc );
                ok $out, qr{\A[^AB]*\z}s, "operator $operator";
            },

            sub {
                $p->Intake->modes( "C" );
                $p->parse_string( $doc );
                ok $out, qr{\A[^AB]*\z}s, "operator $operator";
            },

            sub {
                $p->Intake->modes( "A" );
                $p->parse_string( $doc );
                ok $out, 
                    $doc ne $doc_and
                        ? qr{\A[^B]*<fooA.*<barA[^B]*<fooAB.*<barAB}s
                        : qr{\A[^B]*<fooA.*<barA[^B]*\z}s,
                    "operator $operator";
            },

            sub {
                $p->Intake->modes( "B" );
                $p->parse_string( $doc );
                ok $out,
                    $doc ne $doc_and
                        ? qr{\A[^A]*<fooB.*<barB[^A]*<fooAB.*<barAB}s
                        : qr{\A[^A]*<fooB.*<barB[^A]*\z}s,
                    "operator $operator";
            },

            sub {
                $p->Intake->modes( "A,B" );
                $p->parse_string( $doc );
                ok $out,
                    qr{\A.*<fooA.*<barA.*<fooB.*<barB.*<fooAB.*<barAB}s,
                    "operator $operator";
            },
        )
    } ( $doc_comma, $doc_or, $doc_and )
),

sub {
    $p->Intake->modes( "" );
    $p->parse_string( $doc_not );
    ok $out,
        qr{\A[^B]*<fooAB.*<barAB}s,
        "!A";
},

sub {
    $p->Intake->modes( "C" );
    $p->parse_string( $doc_not );
    ok $out,
        qr{\A[^B]*<fooAB.*<barAB}s,
        "!A";
},

sub {
    $p->Intake->modes( "A" );
    $p->parse_string( $doc_not );
    ok $out, 
        qr{\A[^AB]*\z},
        "!A";
},

sub {
    $p->Intake->modes( "B" );
    $p->parse_string( $doc_not );
    ok $out,
        qr{\A.*<fooA.*<barA.*<fooB.*<barB.*<fooAB.*<barAB}s,
        "!A";
},

sub {
    $p->Intake->modes( "A,B" );
    $p->parse_string( $doc_not );
    ok $out,
        qr{\A[^A]*<fooB.*<barB[^A]*<fooAB.*<barAB}s,
        "!A";
},
);

plan tests => 0+@tests;

$_->() for @tests;

