use strict;

use Test;
use XML::SAX::PurePerl;
use XML::Filter::Merger;
use XML::SAX::Writer;
use UNIVERSAL;

my $p;
my $h;
my $w;

my $out;

my @tests = (
sub {
    $w = XML::SAX::Writer->new( Output => \$out );
    $h = XML::Filter::Merger->new( Handler => $w );
    $p = XML::SAX::PurePerl->new( Handler => $h );
    ok UNIVERSAL::isa( $h, "XML::Filter::Merger" );
},

##
## sequential docs in default (non-IncludeAllRoots) mode
##
sub {
    $out = "";
    $h->start_manifold_document( {} );
    $p->parse_string( "<foo1><bar /></foo1>" );
    $p->parse_string( "<foo2><baz /></foo2>" );
    $h->end_manifold_document( {} );
    $out =~ m{<foo1\s*><bar\s*/><baz\s*/></foo1\s*>}
        ? ok 1
        : ok $out, "something like <foo><bar /><baz /></foo>" ;
},


##
## sequential, IncludeAllRoots mode
##
sub {
    $out = "";
    $h->set_include_all_roots( 1 );
    $h->start_manifold_document( {} );
    $p->parse_string( "<foo1><bar /></foo1>" );
    $p->parse_string( "<foo2><baz /></foo2>" );
    $h->end_manifold_document( {} );

    $out =~ m{<foo1\s*><bar\s*/><foo2\s*><baz\s*/></foo2\s*></foo1\s*>}
        ? ok 1
        : ok qq{This output    $out},
             qq{something like <foo1><bar /><foo2><baz /></foo2></foo1>} ;
},

##
## Nested documents
##
sub {
    $out = "";
    $h->set_include_all_roots( 0 );
    $h->reset;
    $h->start_document( {} );
    $h->start_element( { Name => "foo1" } );
    $p->parse_string( "<foo2><baz /></foo2>" );
    $h->end_element( { Name => "foo1" } );
    $h->end_document( {} );

    $out =~ m{<foo1\s*><baz\s*/></foo1\s*>}
        ? ok 1
        : ok qq{This output    $out},
             qq{something like <foo1><baz /></foo1>} ;

},


sub {
    $out = "";
    $h->set_include_all_roots( 1 );
    $h->reset;
    $h->start_document( {} );
    $h->start_element( { Name => "foo1" } );
    $p->parse_string( "<foo2><baz /></foo2>" );
    $h->end_element( { Name => "foo1" } );
    $h->end_document( {} );

    $out =~ m{<foo1\s*><foo2\s*><baz\s*/></foo2\s*></foo1\s*>}
        ? ok 1
        : ok qq{This output    $out},
             qq{something like <foo1><foo2><baz /></foo2></foo1>} ;

},


##
## Sequential and Nested documents, a deviant corner condition
##
sub {
    $out = "";
    $h->set_include_all_roots( 0 );
    $h->start_manifold_document( {} );
    $h->start_document( {} );
    $h->start_element( { Name => "foo1" } );
    $p->parse_string( "<foo2><baz /></foo2>" );
    $h->end_element( { Name => "foo1" } );
    $h->end_document( {} );
    $p->parse_string( "<foo3><bat /></foo3>" );
    $h->end_manifold_document( {} );

    $out =~ m{<foo1\s*><baz\s*/><bat\s*/></foo1\s*>}
        ? ok 1
        : ok qq{This output    $out},
             qq{something like <foo1><baz /><bat /></foo1>} ;

},


##
## Subclassing
##

sub {
    my $s = do {
        package Subclass;

        use vars qw( @ISA );

        @ISA = qw( XML::Filter::Merger );

        sub characters {
            my $self = shift;

            my $r = $self->SUPER::characters( @_ );

            $self->set_include_all_roots( 1 );

            XML::SAX::PurePerl->new( Handler => $self )->parse_string( "<hey/>" );
            return $r;
        }

        __PACKAGE__ ;
    }->new( Handler => $w );

    $p->set_handler( $s );
    $p->parse_string( "<foo> </foo>" );
    $out =~ m{<foo\s*> <hey\s*/></foo\s*>}
        ? ok 1
        : ok qq{This output    $out},
             qq{something like <foo> <hey /></foo>} ;
},


);

plan tests => scalar @tests;

$_->() for @tests;


