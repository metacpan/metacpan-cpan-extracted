#!/usr/local/bin/thrperl -w

use Test;

my $threaded_perl;
BEGIN {
    $threaded_perl = 
        $] >= "5.008"
            && do {
                require Config;
                $Config::Config{usethreads};
            };

     warn "Need a threaded perl to test threaded mode\n"
         unless $threaded_perl;

     require threads if $threaded_perl;

     ## Enable variable control over threading.
     $XML::Essex::Constants::threading = 1;

#        require threads;
#    }
#    else {
#        if ( ! @ARGV && system( "thrperl -e1" ) == 0 ) {
#            warn "Running thrperl to test threaded mode\n";
#
#            ## If we're exec()ing, it doesn't matter that this won't see
#            ## threads.  If we don't end up exec()ing, it still doesn't
#            ## matter, since we're not going with threads.
#            require XML::Filter::Essex;
#            my $libpath = $INC{"XML/Filter/Essex.pm"};
#            if ( $libpath ) {
#                $libpath =~ s{[\\/]+XML[\\/]+Filter.*[\\/]+Essex\.pm\z}{}i;
#                ## NOTE: this is a hack specific to my system.  If there
#                ## are -I options being passed to the current perl, we
#                ## miss them.
#                exec "thrperl",
#                    "-I$libpath",
#                    $0, "STOP THE INSANITY";
#            }
#            else {
#                warn "No \%INC found for XML::Filter::Essex!\n";
#                warn join ", ", sort keys %INC;
#            }
#        }
#
#        warn "Need a threaded perl to test threaded mode\n";
#    }
}

use XML::Essex::Constants qw( threaded_essex );
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

threads::shared::share( $out ) if $threaded_perl;

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
            # put() returns the result of end_doc(), which X::H::Essex
            # returns to $p, which $p returns to t().
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
        # put()'s return is ignored, as an EOD exception gets thrown
        # and the end_document result is picked up from the
        # :X:G:Essex by X:H:Essex.
        sub {
            put get while 1;
        },
        \"<foo/>"
    ), qr{\A<foo\s*/>\z};
},

# Doesn't yet work under threading because X:Handler::E::_r_share()
# can't detect if something's already shared.
#sub { ok $result, \$out },

sub {
    ok t(
        sub {
            put while get;
        },
        \"<foo/>"
    ), qr{\A<foo\s*/>\z};
},

#sub { ok $result, \$out },

sub {
    ok t(
        sub {
            put get until isa "end_doc";
        },
        \"<foo/>"
    ), qr{\A<foo\s*/>\z};
},

#sub { ok $result, \$out },

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

#sub { ok $result, \$out },

);

plan tests => 2*@tests;

$XML::Essex::Constants::threading = 0;
$_->() for @tests;
$XML::Essex::Constants::threading = 1;
$_->() for @tests;
