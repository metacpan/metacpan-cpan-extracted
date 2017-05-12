#!/usr/local/lib/perl -w

use strict;

use Test;
use XML::SAX::PurePerl;
use XML::Filter::Dispatcher qw( :all );
use XML::SAX::Writer;

use UNIVERSAL;

my( $doc_root_out, $foo_out );

## XML::SAX::Writer clears the output string every start_document() as
## of this writing.  Not sure it always will, but it might.
sub finalize{}
sub output {
   $foo_out .= $_[1];
}

my $doc_string =
   "<root A='1'>a<subroot>b<foo>c<bar/>d</foo>e<foo>f<bar/>g</foo>h</subroot>i</root>";
my $doc = QB->new( "doc", $doc_string );


sub t {
    $doc_root_out = undef;
    $foo_out      = undef;
    $doc->playback( XML::Filter::Dispatcher->new( @_ ) );
}


sub my_ok {
    my ( $got, $expected ) = @_;

    @_ = ( 1 )
        if $got =~ $expected;

    goto &ok;
}

my @tests = (
sub {
    my $foo_handler =
        XML::SAX::Writer->new( Output => bless \( my $foo ), "main" );
    t(
        Rules => [
            'node()' => XML::SAX::Writer->new( Output => \$doc_root_out ),
            'foo' => $foo_handler,
            'bar' => $foo_handler, ## Test preventing multiple start_document()s
        ],
#         Debug => 1,
    );
    $doc_root_out =~ s{\s+/>}{/>}g;
    $foo_out =~ s{\s+/>}{/>}g;
    ok 1;
},
sub { my_ok $doc_root_out, "<root A='1'>a<subroot>bcdefgh</subroot>i</root>" },
sub { my_ok $foo_out, "<foo><bar/></foo><foo><bar/></foo>" },
sub {
    my $foo_handler =
        XML::SAX::Writer->new( Output => bless \( my $foo ), "main" );
    t(
        Rules => [
            'node()'   => $foo_handler,
            'node()'   => $foo_handler,
        ],
#        Debug => 1,
    );
    $foo_out =~ s{\s+/>}{/>}g;
    ok 1;
},
sub { my_ok $foo_out, $doc_string },

## test xrun_next_action
sub {
    my $foo_handler =
        XML::SAX::Writer->new( Output => bless \( my $foo ), "main" );
    t(
        Rules => [
            'node()'  => $foo_handler,
            'subroot' => sub {
                my $self = shift;
                $foo_handler->characters( { Data => "[" } );
                xrun_next_action;
                $foo_handler->characters( { Data => "{" } );
            },
            'end::subroot' => sub {
                my $self = shift;
                $foo_handler->characters( { Data => "}" } );
                xrun_next_action;
                $foo_handler->characters( { Data => "]" } );
            },
        ],
#        Debug => 1,
    );
    $foo_out =~ s{\s+/>}{/>}g;
    ( my $expected = $doc_string )
        =~ s/(<subroot[^>]*>)(.*?)(<\/subroot[^>]*>)/[${1}{$2}${3}]/;

    my_ok $foo_out, $expected;
},

## test something like the xrun_next_action example in the docs
sub {
    my $foo_handler =
        XML::SAX::Writer->new( Output => bless \( my $foo ), "main" );
    t(
        Rules => [
            'node()'  => $foo_handler,
            '*[@A]' => sub {
                my $attr = $_[1]->{Attributes}->{"{}A"};
                local $attr->{Value} = $attr->{Value} + 1;
                xrun_next_action;
            },
        ],
#        Debug => 1,
    );
    $foo_out =~ s{\s+/>}{/>}g;
    ( my $expected = $doc_string ) =~ s/A='1'/A='2'/g;

    my_ok $foo_out, $expected;
},

## See if we can excerpt <foo>
sub {
    my $handler;
    t(
        Rules => [
            'node()' =>
                $handler = XML::SAX::Writer->new( Output => \$doc_root_out ),
            'foo' => undef,
        ],
#        Debug => 1,
    );
    $doc_root_out =~ s{\s+/>}{/>}g;
    ( my $expected = $doc_string ) =~ s{</?foo>}{}g;
    my_ok $doc_root_out, $expected;
},

sub {
    t(
        Handler => XML::SAX::Writer->new( Output => \$doc_root_out ),
        Rules => [
            'node()' => "Handler",
            'foo'      => undef,
        ],
#        Debug => 1,
    );
    $doc_root_out =~ s{\s+/>}{/>}g;
    ( my $expected = $doc_string ) =~ s{</?foo>}{}g;
    my_ok $doc_root_out, $expected;
},

sub {
    t(
        Handlers => {
           Foo => XML::SAX::Writer->new( Output => \$doc_root_out ),
        },
        Rules => [
            'node()' => "Foo",
            'foo'    => undef,
        ],
#        Debug => 1,
    );
    $doc_root_out =~ s{\s+/>}{/>}g;
    ( my $expected = $doc_string ) =~ s{</?foo>}{}g;
    my_ok $doc_root_out, $expected;
},

sub {
    t(
        Handlers => {
           Foo => XML::SAX::Writer->new( Output => \$doc_root_out ),
        },
        Rules => [
            '/*//node()' => "Foo",
        ],
#        Debug => 1,
    );
    $doc_root_out =~ s{\s+/>}{/>}g;
    ( my $expected = $doc_string ) =~ s{</?root.*?>}{}g;
    my_ok $doc_root_out, $expected;
},

sub {
    t(
        Handlers => {
           Foo => XML::SAX::Writer->new( Output => \$doc_root_out ),
        },

        Rules => [
            'node() ' => "Foo",
            '/*/*'      => undef,
        ],
#        Debug => 1,
    );
    $doc_root_out =~ s{\s+/>}{/>}g;
    ( my $expected = $doc_string ) =~ s{</?subroot.*?>}{}g;
    my_ok $doc_root_out, $expected;
},
sub {
    ## This handler will be autostarted because //node() does
    ## not select the document node.
    my $result = t(
        Handlers => {
           Foo => ResultTester->new,
        },

        Rules => [
            'node() ' => "Foo",
        ],
#        Debug => 1,
    );
    ok $result, "result string";
},

sub {
    ## This handler will not be autostarted because //self::node()
    ## selects the document node.
    my $result = t(
        Handlers => {
           Foo => ResultTester->new,
        },

        Rules => [
            '//self::node() ' => "Foo",
        ],
#        Debug => 1,
    );
    ok $result, "result string";
},

## Make sure end_elements don't get dropped in this scenario
sub {
    my $foo_handler =
        XML::SAX::Writer->new( Output => bless \( my $foo ), "main" );
    t(
        Rules => [
            'node()'  => $foo_handler,
            'foo' => [ 'string()' => sub {
                xrun_next_action;
            } ],
        ],
#        Debug => 1,
    );
    $foo_out =~ s{\s+/>}{/>}g;

    my_ok $foo_out, $doc_string;
},

sub {
    my $foo_handler =
        XML::SAX::Writer->new( Output => bless \( my $foo ), "main" );
    my $count = 0;
    t(
        Rules => [
            'node()'  => $foo_handler,
            'foo[*]' => [ 'string()' => sub {
                ++$count;
                xrun_next_action;
            } ],
        ],
#        Debug => 1,
    );
    ok $count, 2;
},
sub {
    $foo_out =~ s{\s+/>}{/>}g;

    my_ok $foo_out, $doc_string;
},

sub {
    my $foo_handler =
        XML::SAX::Writer->new( Output => bless \( my $foo ), "main" );
    my $count = 0;
    t(
        Rules => [
            'node()'  => $foo_handler,
            'foo[bar]' => [ 'string()' => sub {
                ++$count;
                xrun_next_action;
            } ],
        ],
#        Debug => 1,
    );
    ok $count, 2;
},
sub {
    $foo_out =~ s{\s+/>}{/>}g;

    my_ok $foo_out, $doc_string;
},

sub {
    my $foo_handler =
        XML::SAX::Writer->new( Output => bless \( my $foo ), "main" );
    my $count = 0;
    t(
        Rules => [
            'node()'  => $foo_handler,
            'foo[not(zap)]' => [ 'string()' => sub {
                ++$count;
                xrun_next_action;
            } ],
        ],
#        Debug => 1,
    );
    ok $count, 2;
},
sub {
    $foo_out =~ s{\s+/>}{/>}g;

    my_ok $foo_out, $doc_string;
},

);

plan tests => scalar @tests;

$_->() for @tests;

package ResultTester;

BEGIN { @ResultTester::ISA = qw( XML::SAX::Base ); }

sub end_document { "result string" }


## This quick little buffering filter is used to save us the overhead
## of a parse for each test.  This saves me sanity (since I run the test
## suite a lot), allows me to see which tests are noticably slower in
## case something pathalogical happens, and keeps admins from getting the
## impression that this is a slow package based on test suite speed.
package QB;
use vars qw( $AUTOLOAD );
use File::Basename;

sub new {
    my $self = bless [], shift;

    my ( $name, $doc ) = @_;

    my $cache_fn = basename( $0 ) . ".cache.$name";
    if ( -e $cache_fn && -M $cache_fn < -M $0 ) {
        my $old_self = do $cache_fn;
        return $old_self if defined $old_self;
        warn "$!$@";
        unlink $cache_fn;
    }

    require XML::SAX::PurePerl; ## Cannot use ParserFactory; LibXML 1.31 is broken.
    require Data::Dumper;
    my $p = XML::SAX::PurePerl->new( Handler => $self );
    $p->parse_string( $doc );
    if ( open F, ">$cache_fn" ) {
        local $Data::Dumper::Terse;
        $Data::Dumper::Terse = 1;
        print F Data::Dumper::Dumper( $self );
        close F;
    }

    return $self;
}

sub DESTROY;

sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ s/.*://;
    if ( $AUTOLOAD eq "start_element" ) {
        ## Older (and mebbe newer :) X::S::PurePerls reuse the same
        ## hash in end_element but delete the Attributes, so we need
        ## to copy.  And I can't copy everything because some other
        ## overly magical thing dies, haven't tracked down beyond seeing
        ## signs that it's XML::SAX::DocumentLocator::NEXTKEY(/usr/local/lib/perl5/site_perl/5.6.1/XML/SAX/DocumentLocator.pm:72)
        ## but I hear that's fixed in CVS :).
        push @$self, [ $AUTOLOAD, [ { %{$_[0]} } ] ];
    }
    else {
        push @$self, [ $AUTOLOAD, [ $_[0] ] ];
    }
}

sub playback {
    my $self = shift;
    my $h = shift;
    my $r;
    for ( @$self ) {
        my $m = $_->[0];
        no strict "refs";
        $r = $h->$m( @{$_->[1]} );
    }
    return $r;
}
