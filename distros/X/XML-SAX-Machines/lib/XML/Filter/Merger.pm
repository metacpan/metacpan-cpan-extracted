package XML::Filter::Merger;
{
  $XML::Filter::Merger::VERSION = '0.46';
}

# ABSTRACT: Assemble multiple SAX streams in to one document


use base qw( XML::SAX::Base );

use strict;
use Carp;
use XML::SAX::EventMethodMaker qw( sax_event_names compile_missing_methods );

sub _logging() { 0 };


sub new {
    my $self = shift->SUPER::new( @_ );
    $self->reset;
    return $self;
}


sub reset {
    my $self = shift;
    $self->{DocumentDepth}           = 0;
    $self->{DocumentCount}           = 0;
    $self->{TailEvents}              = undef;
    $self->{ManifoldDocumentStarted} = 0;
    $self->{Cutting}                 = 0;
    $self->{Depth}                   = 0;
    $self->{RootEltSeen}             = 0;
    $self->{AutoReset}               = 0;
}


sub start_manifold_document {
    my $self = shift;
    $self->reset;
    $self->{ManifoldDocumentStarted} = 1;

## A little fudging here until XML::SAX::Base gets a new release
$self->{Methods} = {};
}


sub _log {
    my $self = shift;

    warn "MERGER: ",
        $self->{DocumentCount}, " ",
        "| " x $self->{DocumentDepth},
        ". " x $self->{Depth},
        @_,
        "\n";
}


sub _cutting {
    my $self = shift;

#    if ( @_ ) {
#        my $v = shift;
#warn "MERGER: CUTTING ", $v ? "SET!!" : "CLEARED!!", "\n"
#   if ( $v && ! $self->{Cutting} ) || ( ! $v && $self->{Cutting} );
#        $self->{Cutting} = $v;
#    }

    my $v = shift;

    $v = 1
        if ! defined $v
            && ( $self->{DocumentCount} > 1
               || $self->{DocumentDepth} > 1
            )
            && ! $self->{Depth};


    $self->_log(
        $v ? () : "NOT ",
        "CUTTING ",
        do { my $c = (caller(1))[3]; $c =~ s/.*:://; $c }, 
        " (doccount=$self->{DocumentCount}",
        " docdepth=$self->{DocumentDepth}",
        " depth=$self->{Depth})"
    ) if _logging;
    return $v;

    return $self->{Cutting};
}


sub _saving {
    my $self = shift;

    return
        $self->{ManifoldDocumentStarted}
        && $self->{DocumentCount} == 1
        && $self->{DocumentDepth} == 1
        && $self->{RootEltSeen};
}


sub _push {
    my $self = shift;

    $self->_log( "SAVING ", $_[0] ) if _logging;

    push @{$self->{TailEvents}}, [ @_ ];

    return undef;
}


sub start_document {
    my $self = shift;

    $self->reset if $self->{AutoReset};

    push @{$self->{DepthStack}}, $self->{Depth};

    ++$self->{DocumentCount} unless $self->{DocumentDepth};
    ++$self->{DocumentDepth};
    $self->{Depth} = 0;

    $self->SUPER::start_document( @_ )
        unless $self->_cutting;

}

sub end_document {
    my $self = shift;

    my $r;

    unless ( $self->_cutting ) {
        if ( $self->_saving ) {
            $self->_push( "end_document", @_ );
        }
        else {
            $r = $self->SUPER::end_document( @_ );
        }
    }

    --$self->{DocumentDepth};
    $self->{Depth} = pop @{$self->{DepthStack}};

    return $r;
}


sub start_element {
    my $self = shift ;

    my $r;

    $r = $self->SUPER::start_element( @_ )
        unless $self->_cutting( $self->{IncludeAllRoots} ? 0 : () );

    ++$self->{Depth};

    return $r;
}


sub end_element {
    my $self = shift ;

    --$self->{Depth};
    $self->{RootEltSeen} ||= $self->{DocumentDepth} == 1 && $self->{Depth} == 0;

    return undef if $self->_cutting( $self->{IncludeAllRoots} ? 0 : () );

    return $self->_saving
        ? $self->_push( "end_element", @_ )
        : $self->SUPER::end_element( @_ );
}

compile_missing_methods __PACKAGE__, <<'TEMPLATE_END', sax_event_names;
sub <EVENT> {
    my $self = shift;

    return undef if $self->_cutting;

    return $self->_saving
        ? $self->_push( "<EVENT>", @_ )
        : $self->SUPER::<EVENT>( @_ );
}
TEMPLATE_END


sub in_master_document {
    my $self = shift;

    return $self->{DocumentCount} == 1 && $self->{DocumentDepth} <= 1;
}


sub document_depth {
    shift->{DocumentDepth} - 1;
}




sub element_depth {
    shift->{Depth} - 1;
}



sub top_level_document_number {
    shift->{DocumentCount} - 1;
}






sub end_manifold_document {
    my $self = shift;

    my $r;
    if ( $self->{TailEvents} ) {
	for ( @{$self->{TailEvents}} ) {
	    my $sub_name = shift @$_;
            $self->_log( "PLAYING BACK $sub_name" ) if _logging;
            $sub_name = "SUPER::$sub_name";
	    $r = $self->$sub_name( @$_ );
	}
    }
    $self->{ManifoldDocumentStarted} = 0;
    $self->{AutoReset} = 1;
    return $r;
}


sub set_include_all_roots {
    my $self = shift;
    $self->{IncludeAllRoots} = shift;
}


1;

__END__

=pod

=head1 NAME

XML::Filter::Merger - Assemble multiple SAX streams in to one document

=head1 VERSION

version 0.46

=head1 SYNOPSIS

    ## See XML::SAX::Manifold and XML::SAX::ByRecord for easy ways
    ## to use this processor.

    my $w = XML::SAX::Writer->new(           Output => \*STDOUT );
    my $h = XML::Filter::Merger->new(        Handler => $w );
    my $p = XML::SAX::ParserFactory->parser( Handler => $h );

    ## To insert second and later docs in to the first doc:
    $h->start_manifold_document( {} );
    $p->parse_file( $_ ) for @ARGV;
    $h->end_manifold_document( {} );

    ## To insert multiple docs inline (especially useful if
    ## a subclass does the inline parse):
    $h->start_document( {} );
    $h->start_element( { ... } );
    ....
    $h->start_element( { Name => "foo", ... } );
    $p->parse_uri( $uri );   ## Body of $uri inserted in <foo>...</foo>
    $h->end_element( { Name => "foo", ... } );
    ...

=head1 DESCRIPTION

Combines several documents in to one "manifold" document.  This can be
done in two ways, both of which start by parsing a master document in to
which (the guts of) secondary documents will be inserted.

=head2 Inlining Secondary Documents

The most SAX-like way is to simply pause the parsing of the master
document between the two events where you want to insert a secondard
document and parse the complete secondard document right then and there
so it's events are inserted in the pipeline at the right spot.
XML::Filter::Merger only passes the content of the secondary document's
root element:

    my $h = XML::Filter::Merger->new( Handler => $w );
    $h->start_document( {} );
    $h->start_element( { Name => "foo1" } );
        $p->parse_string( "<foo2><baz /></foo2>" );
    $h->end_element( { Name => "foo1" } );
    $h->end_document( {} );

results in C<$w> seeing a document like C<< <foo1><baz/></foo1> >>.

This technique is especially useful when subclassing XML::Filter::Merger
to implement XInclude-like behavior.  Here's a useless example that
inserts some content after each C<characters()> event:

    package Subclass;

    use vars qw( @ISA );

    @ISA = qw( XML::Filter::Merger );

    sub characters {
        my $self = shift;

        return $self->SUPER::characters( @_ )  ## **
            unless $self->in_master_document;  ## **

        my $r = $self->SUPER::characters( @_ );

        $self->set_include_all_roots( 1 );

        XML::SAX::PurePerl->new( Handler => $self )->parse_string( "<hey/>" );
        return $r;
    }

    ## **: It is often important to use the recursion guard shown here
    ## to protect the decision making logic that should only be run on
    ## the events in the master document from being run on events in the
    ## subdocument.  Of course, if you want to apply the logic
    ## recursively, just leave the guard code out (and, yes, in this
    ## example, th guard code is phrased in a slightly redundant fashion,
    ## but we want to make the idiom clear).

Feeding this filter C<< <foo> </foo> >> results in C<< <foo>
<hey/></foo> >>.  We've called C<set_include_all_roots( 1 )> to get the
secondary document's root element included.

=head2 Inserting Manifold Documents

A more involved way suitable to handling consecutive documents it to use
the two non-SAX events--C<start_manifold_document> and
C<end_manifold_document>--that are called before the first document to
be combined and after the last one, respectively.

The first document to be started after the
C<start_manifold_document> is the master document and is emitted as-is
except that it will contain the contents of all of the other documents
just before the root C<end_element()> tag.  For example:

    $h->start_manifold_document( {} );
    $p->parse_string( "<foo1><bar /></foo1>" );
    $p->parse_string( "<foo2><baz /></foo2>" );
    $h->end_manifold_document( {} );

results in C<< <foo><bar /><baz /></foo> >>.

=head2 The details

In case the above was a bit vague, here are the rules this filter lives
by.

For the master document:

=over

=item *

Events before the root C<end_element> are forwarded as received.
Because of the rules for secondary documents, any secondary documents
sent to the filter in the midst of a master document will be
inserted inline as their events are received.

=item *

All remaining events, from the root C<end_element> are
buffered until the end_manifold_document() received, and are then
forwarded on.

=back

For secondary documents:

=over

=item *

All events before the root C<start_element> are discarded.  There is
no way to recover these (though we can add an option for most non-DTD
events, I believe).

=item *

The root C<start_element> is discarded by default, or forwarded if
C<set_include_all_roots( $v )> has been used to set a true value.

=item *

All events up to, but not including, the root C<end_element> are
forwarded as received.

=item *

The root C<end_element> is discarded or forwarded if the matching
C<start_element> was.

=item *

All remaining events until and including the C<end_document> are
forwarded and processing.

=item *

Secondary documents may contain other secondary documents.

=item *

Secondary documents need not be well formed.  The must, however, be well
balanced.

=back

This requires very little buffering and is "most natural" with the
limitations:

=over

=item *

All of each secondary document's events must all be received
between two consecutive events of it's master document.  This is because
most master document events are not buffered and this filter cannot
tell from which upstream source a document came.

=item *

If the master document should happen to have some egregiously large
amount of whitespace, commentary, or illegal events after the root
element, buffer memory could be huge.  This should be exceedingly rare,
even non-existent in the real world.

=item *

If any documents are not well balanced, the result won't be.

=item *

=back

=head1 NAME

XML::Filter::Merger - Assemble multiple SAX streams in to one document

=head1 METHODS

=over

=item new

    my $d = XML::Filter::Merger->new( \%options );

=item reset

Clears the filter after an accident.  Useful when reusing the filter.
new() and start_manifold_document() both call this.

=item start_manifold_document

This must be called before the master document's C<start_document()>
if you want XML::Filter::Merger to insert documents that will be sent
after the master document.

It does not need to be called if you are going to insert secondary
documents by sending their events in the midst of processing the master
document.

It is passed an empty ({}) data structure.

=head1 Additional Methods

These are provided to make it easy for subclasses to find out roughly
where they are in the document structure.  Generally, these should be
called after calling SUPER::start_...() and before calling
SUPER::end_...() to be accurate.

=over

=item in_master_document

Returns TRUE if the current event is in the first top level document.

=item document_depth

Gets how many nested documents surround the current document.  0 means that you
are in a top level document.  In manifold mode, This may or may not be a
secondary document: secondary documents may also follow the primary
document, in which case they have a document depth of 0.

=item element_depth

Gets how many nested elements surround the current element in the
current input document.  Does not count elements from documents
surrounding this document.

=item top_level_document_number

Returns the number of the top level document in a manifold document.
This is 0 for the first top level document, which is always the master
document.

=item end_manifold_document

This must be called after the last document's end_document is called.  It
is passed an empty ({}) data structure which is passed on to the
next processor's end_document() call.  This call also causes the
end_element() for the root element to be passed on.

=item set_include_all_roots

    $h->set_include_all_roots( 1 );

Setting this option causes the merger to include all root element nodes,
not just the first document's.  This means that later documents are
treated as subdocuments of the output document, rather than as envelopes
carrying subdocuments.

Given two documents received are:

 Doc1:   <root1><foo></root1>

 Doc1:   <root2><bar></root2>

 Doc3:   <root3><baz></root3>

then with this option cleared (the default), the result looks like:

    <root1><foo><bar><baz></root1>

.  This is useful when processing document oriented XML and each
upstream filter channel gets a complete copy of the document.  This is
the case with the machine L<XML::SAX::Manifold> and the splitting filter
L<XML::Filter::Distributor>.

With this option set, the result looks like:

    <root1><foo><root2><bar></root2><root3><baz></root3></root1>

This is useful when processing record oriented XML, where the first
document only contains the preamble and postamble for the records and
not all of the records.  This is the case with the machine
L<XML::SAX::ByRecord> and the splitting filter
L<XML::Filter::DocSplitter>.

The two splitter filters mentioned set this feature appropriately.

=back

=head1 LIMITATIONS

The events before and after a secondary document's root element events
are discarded.  It is conceivable that characters, PIs and commentary
outside the root element might need to be kept.  This may be added as an
option.

The DocumentLocators are not properly managed: they should be saved and
restored around each each secondary document.

Does not yet buffer all events after the first document's root end_element
event.

If these bite you, contact me.

=head1 AUTHOR

    Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

    Copyright 2002, Barrie Slaymaker, All Rights Reserved.

You may use this module under the terms of the Artistic, GNU Public, or
BSD licenses, you choice.

=head1 AUTHORS

=over 4

=item *

Barry Slaymaker

=item *

Chris Prather <chris@prather.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Barry Slaymaker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
