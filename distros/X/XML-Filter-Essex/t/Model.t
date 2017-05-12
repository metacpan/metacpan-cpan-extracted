use Test;
use XML::Essex::Model;
use strict;

sub n {
    $_ = shift->new( @_ );
    "". $_;
}

my @tests = (

## start_document

sub {
    ok n( "XML::Essex::Event::start_document" ), qr{\Astart_document\(.*\)\z};
},
sub { ok $_->isa( "XML::Essex::Event::start_document" ) },
sub { ok $_->isa( "start_document" ) },
sub { ok $_->type, "start_document" },
sub { ok $_->isa( "start_doc" ) },

sub {
    ok n( "XML::Essex::Event::start_doc" ), qr{\Astart_document\(.*\)\z};
},
sub { ok $_->isa( "XML::Essex::Event::start_document" ) },

## xml_decl

sub {
    ok n(
        "XML::Essex::Event::xml_decl",
        Version => 1,
        Encoding => 2,
        Standalone => "yes"
    ),
    qr{\A<\?xml version="1" encoding="2" standalone="yes"\?>\z};
},
sub { ok $_->isa( "XML::Essex::Event::xml_decl" ) },
sub { ok $_->type( "xml_decl" ) },
sub { ok $_->isa( "xml_decl" ) },


## end_document

sub {
    ok n( "XML::Essex::Event::end_document" ), qr{\Aend_document\(.*\)\z};
},
sub { ok $_->isa( "XML::Essex::Event::end_document" ) },
sub { ok $_->type, "end_document" },
sub { ok $_->isa( "end_document" ) },
sub { ok $_->isa( "end_doc" ) },

sub {
    ok n( "XML::Essex::Event::end_doc" ), qr{\Aend_document\(.*\)\z};
},
sub { ok $_->isa( "XML::Essex::Event::end_document" ) },


## start_element

sub {
    ok n(
        "XML::Essex::Event::start_element", "foo", { "a" => "b" }
    ),
    qr{\A<foo a="b"\s*>\z};
},
sub { ok join( ",", sort keys %$_ ), "a" },
sub { ok join( ",", $_->jclark_keys ), "{}a" },
sub { ok $_->{"{}a"}, "b" },
sub { ok $_->{a},     "b" },
sub { ok join( ",", sort keys %$_ ), "a" },
sub { ok $_->{c},     ""  },
sub { ok join( ",", sort keys %$_ ), "a,c" },
sub { $_->{c} = "d"; ok $_->{c}, "d"  },
sub { ok join( ",", sort keys %$_ ), "a,c" },
sub { $_->{e} = "f"; ok $_->{e}, "f"  },
sub { ok join( ",", sort keys %$_ ), "a,c,e" },
sub { delete $_->{c}; ok join( ",", sort keys %$_ ), "a,e" },

sub {
    ok n(
        "XML::Essex::Event::start_element", {
            LocalName => "foo",
            Attributes => {
                "{}a" => { LocalName => "a", Value => '"' },
                "{}b" => { LocalName => "b", Value => "'" },
                "{}c" => { LocalName => "c", Value => "<" },
            },
        }
    ),
    qr{\A<foo a=""" b="'" c="<">\z}; #'
},
sub { ok $_->isa( "XML::Essex::Event::start_element" ) },
sub { ok $_->type, "start_element" },
sub { ok $_->isa( "start_element" ) },
sub { ok $_->isa( "start_elt" ) },

sub {
    ok n( "XML::Essex::Event::start_elt", $_ ), qr{\A<foo a=""" b="'" c="<">\z}; #'
},
sub { ok $_->isa( "XML::Essex::Event::start_element" ) },

## end_element

sub {
    ok n(
            "XML::Essex::Event::end_element", "foo"
    ),
    qr{\A</foo>\z};
},
sub {
    ok n(
            "XML::Essex::Event::end_element",
            {
                Name      => "foo",
                LocalName => "foo",
            },
    ),
    qr{\A</foo>\z};
},
sub { ok $_->isa( "XML::Essex::Event::end_element" ) },
sub { ok $_->type, "end_element" },
sub { ok $_->isa( "end_element" ) },
sub { ok $_->isa( "end_elt" ) },

sub {
    ok n( "XML::Essex::Event::end_elt", $_ ), qr{\A</foo>\z};
},
sub { ok $_->isa( "XML::Essex::Event::end_element" ) },

## element

sub {
local $XML::FOO=1;
    ok n(
        "XML::Essex::Event::element", "foo", { a => "b" }, "bar"
    ),
    qr{\A<foo a="b"\s*>bar</foo\s*>\z};
},

## Most of the things you can do with the attr hash are tested
## up above with start_element.
sub { ok join( ",", sort keys %$_ ), "a" },
sub { ok join( ",", $_->jclark_keys ), "{}a" },
sub { ok $_->{a},     "b" },

sub { ok join( ",", @$_ ), "bar" },
sub { unshift @$_, "foo"; ok join( ",", @$_ ), "foo,bar" },
sub { push @$_, "baz";    ok join( ",", @$_ ), "foo,bar,baz" },


sub {
    ok n(
        "XML::Essex::Event::element", {
            LocalName => "foo",
            Attributes => {
                "{}a" => { LocalName => "a", Value => '"' },
                "{}b" => { LocalName => "b", Value => "'" },
                "{}c" => { LocalName => "c", Value => "<" },
            },
        }
    ),
    qr{\A<foo a=""" b="'" c="<"></foo\s*>\z}; #';
},
sub { ok $_->isa( "XML::Essex::Event::element" ) },
sub { ok $_->type, "element" },
sub { ok $_->isa( "element" ) },
sub { ok $_->isa( "elt" ) },

sub {
    ok n( "XML::Essex::Event::elt", $_ ), qr{\A<foo a=""" b="'" c="<"></foo\s*>\z}; #'
},
sub { ok $_->isa( "XML::Essex::Event::element" ) },

## characters

sub {
    ok n( "XML::Essex::Event::characters", "<hey!" ), "<hey!"
},
sub {
    ok n( "XML::Essex::Event::characters", { Data => "<hey!" } ), "<hey!"
},
sub { ok $_->isa( "XML::Essex::Event::characters" ) },
sub { ok $_->type, "characters" },
sub { ok $_->isa( "characters" ) },
sub { ok $_->isa( "chars" ) },

sub {
    ok n( "XML::Essex::Event::chars", $_ ), qr{\A<hey!\z};
},
sub { ok $_->isa( "XML::Essex::Event::characters" ) },

## comment

sub {
    ok n( "XML::Essex::Event::comment", "<hey!" ), "<hey!"
},
sub {
    ok n( "XML::Essex::Event::comment", { Data => "<hey!" } ), "<hey!"
},
sub { ok $_->isa( "XML::Essex::Event::comment" ) },
sub { ok $_->type, "comment" },
sub { ok $_->isa( "comment" ) },

);

plan tests => 0+@tests;

for my $t ( @tests ) { $t->() }
