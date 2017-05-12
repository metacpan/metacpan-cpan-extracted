use Test;

use XML::Filter::Essex;
use XML::SAX::PurePerl;
use XML::SAX::Writer;

BEGIN {
    eval "use Test::Differences;1" || eval "sub eq_or_diff { goto &ok }";
}


@Foo::ISA = qw( XML::Filter::Essex );

sub Foo::main {
    "Result Value";
}

use strict;

my ( $p, $h, $w );
my ( $out, $result );

sub t {
    my @main;
    @main = ( Main => shift ) if @_ && ref $_[0] eq "CODE";
    my $doc;
    $doc = pop if @_ && ref $_[-1] eq "SCALAR";

    my %opts = @_;

    $h = XML::Filter::Essex->new( @main, %opts );

    $out = undef;
    $h->set_handler( XML::SAX::Writer->new( Output => \$out ) )
        unless $opts{Handler};

    $result = undef;
    if ( defined $doc ) {
        $p = XML::SAX::PurePerl->new( Handler => $h );
        $result = $p->parse_string( $$doc );
    }
    else {
        $result = $h->execute;
    }
    return defined $out ? $out : $result;
}


my @tests = (
sub {
    ok 1,
},

sub {
    ok t( sub { 1 }, \"<foo/>" ), 1;
},

sub {
    ok t(
        sub {
            put
                start_doc,
                start_elt( "foo", { "a" => 1 } ),
                end_elt(   "foo" ),
                end_doc;
        },
    ), qr{\A<foo\s*a=['"]1['"]\s*/>\z};
},

sub { ok $result, \$out },  ## X:S:W returns the scalar ref

# Several basic get/put loops

sub {
    ok t(
        sub {
            put get while 1;
        },
        \"<foo/>"
    ), qr{\A<foo\s*/>\z};
},

sub { ok $result, \$out },

sub {
    ok t(
        sub {
            put while get;
        },
        \"<foo/>"
    ), qr{\A<foo\s*/>\z};
},

sub { ok $result, \$out },

sub {
    ok t(
        sub {
            put get until isa "end_doc";
        },
        \"<foo/>"
    ), qr{\A<foo\s*/>\z};
},

sub { ok $result, \$out },

sub {
    ok t(
        sub {
            while (1) {
                get;
                return put if isa "end_doc";
                put;
            }
        },
        \"<foo/>"
    ), qr{\A<foo\s*/>\z};
},

# put()

sub {
    ok t(
        sub {
            put start_doc, [ foo => { a => "b" }, "bar" ], end_doc;
        },
    ), qr{<foo a=["']b["']>bar</foo>};
},

# put()'s missing end_element insertion

sub {
    ok t(
        sub {
            put start_doc, start_elt( "foo" ), end_elt, end_doc;
        },
    ), qr{<foo\s*/>};
},

# path()

sub {
    eq_or_diff t(
        sub {
            put start_doc, start_elt( "out" ), "\n";
            while (1) {
                get;
                put "$_", path, "\n" if isa "start_elt";
                last if isa "end_doc";
            }
            put end_elt, "\n", end_doc;
        },
        \"<foo/>"
    ), <<END_PATHS
<out>
&lt;foo&gt;/foo
</out>
END_PATHS
},

sub { ok $result, \$out },

# Get something that doesn't exist; see if the doc is passed through
sub {
    ok t(
        sub {
            get "processing-instruction()";
        },
        \"<foo/>"
    ), qr{\A<foo\s*/>\z};
},

sub { ok $result, \$out },

);

plan tests => 0+@tests;

$_->() for @tests;
