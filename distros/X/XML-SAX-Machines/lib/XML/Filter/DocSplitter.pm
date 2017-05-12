package XML::Filter::DocSplitter;
{
  $XML::Filter::DocSplitter::VERSION = '0.46';
}
# ABSTRACT: Multipass processing of documents


use XML::SAX::Base;

@ISA = qw( XML::SAX::Base );

@EXPORT_OK = qw( DocSplitter );

use strict;
use Carp;
use XML::SAX::EventMethodMaker qw( sax_event_names compile_missing_methods );


## Inherited.


sub set_aggregator {
    my $self = shift;
    $self->{Aggregator} = shift;

    $self->{AggregatorPassThrough} = XML::SAX::Base->new()
        unless $self->{AggregatorPassThrough};

    $self->{AggregatorPassThrough}->set_handler( $self->{Aggregator} );
}



sub get_aggregator {
    my $self = shift;

    return $self->{Aggregator};
}



sub set_split_path {
    my $self = shift;
    my $pat = $self->{SplitPoint} = shift;
    $pat = "/$pat"
        unless substr( $pat, 0, 1 ) eq "/";
    $pat = quotemeta $pat;

    $pat =~ s{\\\*}{[^/]*}g;  ## Hmmm, * will match nodes with 0 length names ""
    $pat =~ s{\\/\\/}{/.*/}g;
    $pat =~ s{^\\/}{^}g;

    $self->{SplitPathRe} = qr/$pat(?!\n)\Z/;

    return undef;
}



sub get_split_path {
    my $self = shift;

    return $self->{SplitPoint};
}


sub _check_stack {
    my $self = shift;

    my $stack = join "/", @{$self->{Stack}};

    $stack =~ $self->{SplitPathRe};
}


sub start_document {
    my $self = shift;

    my $aggie = $self->get_aggregator;
    $aggie->start_manifold_document( @_ )
        if $aggie && $aggie->can( "start_manifold_document" );
    $aggie->set_include_all_roots( 1 )
        if $aggie && $aggie->can( "set_include_all_roots" );

    $aggie->start_document( @_ );

    $self->{Stack}       = [];
    $self->{Splitting}   = 0;
    $self->set_split_path( "/*/*" )
        unless defined $self->get_split_path;

    ## don't pass on the start_document, we'll do that once for each
    ## record.
    return undef;
}


sub start_element {
    my $self = shift;
    my ( $elt ) = @_;

    push @{$self->{Stack}}, $elt->{Name};

    if ( ! $self->{Splitting} && $self->_check_stack ) {
        ++$self->{Splitting};
        $self->SUPER::start_document( {} );
    }
    elsif ( $self->{Splitting} ) {
        ++$self->{Splitting};
    }

    if ( $self->{Splitting} ) {
        return $self->SUPER::start_element( @_ );
    }

    $self->{AggregatorPassThrough}->start_element( @_ )
        if $self->{AggregatorPassThrough};

    return undef;
}


sub end_element {
    my $self = shift;
    my ( $elt ) = @_;

    pop @{$self->{Stack}};

    my $r ;
    if ( $self->{Splitting} ) {
        $r = $self->SUPER::end_element( @_ )
    }
    else {
        $r = $self->{AggregatorPassThrough}->end_element( @_ )
            if $self->{AggregatorPassThrough};
    }

    if ( $self->{Splitting} && ! --$self->{Splitting} ) {
        ## ignore the result code, we'll get it in end_document.
        $self->SUPER::end_document( {} );
    }

    return $r;
}


sub end_document {
    my $self = shift;

    my $aggie = $self->get_aggregator;

    my $r;

    if ( $aggie ) {
        $r = $aggie->end_document( @_ );
        $r = $aggie->end_manifold_document( @_ )
            if $aggie->can( "end_manifold_document" );
    }

    return $r;
}


compile_missing_methods __PACKAGE__, <<'TPL_END', sax_event_names ;
sub <EVENT> {
    my $self = shift;
    return $self->SUPER::<EVENT>( @_ )
        if $self->{Splitting};

    $self->{AggregatorPassThrough}-><EVENT>( @_ )
        if $self->{AggregatorPassThrough};
}
TPL_END





1;

__END__

=pod

=head1 NAME

XML::Filter::DocSplitter - Multipass processing of documents

=head1 VERSION

version 0.46

=head1 SYNOPSIS

    ## See XML::SAX::???? for an easier way to use this filter.

    use XML::SAX::Machines qw( Machine ) ;

    my $m = Machine(
        [ Intake => "XML::Filter::DocSplitter" => qw( Filter ) ],
        [ Filter => "My::Filter"               => qw( Merger ) ],
        [ Merger => "XML::Filter::Merger" => qw( Output ) ],
        [ Output => \*STDOUT ],
    );

    ## Let the distributor coordinate with the merger
    ## XML::SAX::Manifold does this for you.
    $m->Intake->set_aggregator( $m->Merger );

    $m->parse_file( "foo" );

=head1 DESCRIPTION

XML::Filter::DocSplitter is a SAX filter that allows you to apply a
filter to repeated sections of a document.  It splits a document up at a
predefined elements in to multiple documents and the filter is run on
each document.  The result can be left as a stream of separate documents
or combined back in to a single document using a filter like
L<XML::SAX::Merger>.

By default, the input document is split in all children of the root
element.  By that reckoning, this document has three sub-documents in
it:

    <doc>
        <subdoc> .... </subdoc>
        <subdoc> .... </subdoc>
        <subdoc> .... </subdoc>
    </doc>

When using without an aggregator, all events up to the first record are
lost; with an aggregator, they are passed directly in to the aggregator
as the "first" document.  All elements between the records (the "\n    "
text nodes, in this case) are also passed directly to the merger (these
will arrive between the end_document and start_document calls for each
of the records), as are all events from the last record until the end
of the input document.  This means that the first document, as seen by
the merger, is incomplete; it's missing it's end_element, which is
passed later.

The approach of passing events from the input document right on through
to the merger differs from the way L<XML::Filter::Distributor> works.

This class is derived from L<XML::SAX::Base>, see that for details.

=head1 NAME

XML::Filter::DocSplitter - Multipass processing of documents

=head1 METHODS

=over

=item new

    my $d = XML::Filter::DocSplitter->new(
        Handler    => $h,
        Aggregator => $a,    ## optional
    );

=item set_aggregator

    $h->set_aggregator( $a );

Sets the SAX filter that will stitch the resulting subdocuments back
together.  Set to C<undef> to prevent such stitchery.

The aggregator should support the C<start_manifold_document>,
C<end_manifold_document>, and C<set_include_all_roots> methods as
described in L<XML::Filter::Merger>.

=item get_aggregator

    my $a = $h->get_aggregator;

Gets the SAX filter that will stitch the resulting subdocuments back
together.

=item set_split_path

    $h->set_split_path( "/a/b/c" );

Sets the pattern to use when splitting the document.  Patterns are a
tiny little subset of the XPath language:

    Pattern     Description
    =======     ===========
    /*/*        splits the document on children of the root elt (default)
    //record    splits each <record> elt in to a document
    /*/record   splits each <record> child of the root elt
    /a/b/c/d    splits each of the <d> elts in to a document

=item get_split_path

    my $a = $h->get_split_path;

=head1 LIMITATIONS

Can only feed a single aggregator at the moment :).  I can fix this with
a bit of effort.

=head1 AUTHOR

    Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

    Copyright 2000, Barrie Slaymaker, All Rights Reserved.

You may use this module under the terms of the Artistic, GPL, or the BSD
licenses.

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
