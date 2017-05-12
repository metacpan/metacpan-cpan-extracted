use strict;

use Test;
use XML::SAX::Machines qw( Pipeline );

my $m;

my $out;

my @tests = (
(
    map {
        my $m = $_;
        sub {
            $out = "";
            ok $m->isa( "XML::SAX::Machine" );
        },

        sub { $m->start_document;                    ok 1, 1, "start_document"},
        sub { $m->start_element( { Name => "foo" } );ok 1, 1, "start_elt foo" },
        sub { $m->start_element( { Name => "bar" } );ok 1, 1, "start_elt bar" },
        sub { $m->end_element(   { Name => "bar" } );ok 1, 1, "end_elt bar"   },
        sub { $m->end_element(   { Name => "foo" } );ok 1, 1, "end_elt foo"   },
        sub { $m->end_document;                      ok 1, 1, "end_document"  },

        sub {
            $out =~ m{<foo\s*><bar\s*/></foo\s*>}
                ? ok 1
                : ok $out, "something like <foo><bar /></foo>" ;
        },

        sub {
            $out = "";
            ok $m->parse_string( "<foo><bar /></foo>" );
        },

        sub {
            $out =~ m{<foo\s*><bar\s*/></foo\s*>}
                ? ok 1
                : ok $out, "something like <foo><bar /></foo>" ;
        },
    } (
        Pipeline( \$out ),
        Pipeline(
            "XML::SAX::Base",
            \$out
        ),
        Pipeline(
            "XML::SAX::Base",
            "XML::SAX::Base",
            \$out
        ),
        Pipeline(
            "XML::SAX::Base",
            XML::SAX::Writer->new( Output => \$out ),
        ),
        Pipeline(
            "XML::SAX::Base",
            {
                Handler => XML::SAX::Writer->new( Output => \$out ),
            },
        ),
    )
),
);

plan tests => scalar @tests;

$_->() for @tests;
