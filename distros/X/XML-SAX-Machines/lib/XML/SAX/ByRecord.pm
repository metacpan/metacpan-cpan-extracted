package XML::SAX::ByRecord;
{
  $XML::SAX::ByRecord::VERSION = '0.46';
}
# ABSTRACT: Record oriented processing of (data) documents


use base qw( XML::SAX::Machine );

use strict;
use Carp;


sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my @options_hash_if_present = @_ && ref $_[-1] eq "HASH" ? pop : () ;

    my $stage_num = 0;

    my @machine_spec = (
        [ Intake => "XML::Filter::DocSplitter" ],
        map( [ "Stage_" . $stage_num++ => $_   ], @_ ),
        [ Merger => "XML::Filter::Merger" => qw( Exhaust ) ],
    );

    push @{$machine_spec[$_]}, "Stage_" . $_
        for 0..$#machine_spec-2 ;

    push @{$machine_spec[-2]}, "Merger"
        if @machine_spec;

    my $self = $proto->SUPER::new(
        @machine_spec,
        @options_hash_if_present
    );

    my $distributor = $self->find_part( 0 );
    $distributor->set_aggregator( $self->find_part( -1 ) )
        if $distributor->can( "set_aggregator" );

    return $self;
}


1;

__END__

=pod

=head1 NAME

XML::SAX::ByRecord - Record oriented processing of (data) documents

=head1 VERSION

version 0.46

=head1 SYNOPSIS

    use XML::SAX::Machines qw( ByRecord ) ;

    my $m = ByRecord(
        "My::RecordFilter1",
        "My::RecordFilter2",
        ...
        {
            Handler => $h, ## optional
        }
    );

    $m->parse_uri( "foo.xml" );

=head1 DESCRIPTION

XML::SAX::ByRecord is a SAX machine that treats a document as a series
of records.  Everything before and after the records is emitted as-is
while the records are excerpted in to little mini-documents and run one
at a time through the filter pipeline contained in ByRecord.

The output is a document that has the same exact things before, after,
and between the records that the input document did, but which has run
each record through a filter.  So if a document has 10 records in it,
the per-record filter pipeline will see 10 sets of ( start_document,
body of record, end_document ) events.  An example is below.

This has several use cases:

=over

=item *

Big, record oriented documents

Big documents can be treated a record at a time with various DOM oriented
processors like L<XML::Filter::XSLT>.

=item *

Streaming XML

Small sections of an XML stream can be run through a document processor
without holding up the stream.

=item *

Record oriented style sheets / processors

Sometimes it's just plain easier to write a style sheet or SAX filter that
applies to a single record at at time, rather than having to run through a
series of records.

=back

=head2 Topology

Here's how the innards look:

   +-----------------------------------------------------------+
   |                  An XML:SAX::ByRecord                     |
   |    Intake                                                 |
   |   +----------+    +---------+         +--------+  Exhaust |
 --+-->| Splitter |--->| Stage_1 |-->...-->| Merger |----------+----->
   |   +----------+    +---------+         +--------+          |
   |               \                            ^              |
   |                \                           |              |
   |                 +---------->---------------+              |
   |                   Events not in any records               |
   |                                                           |
   +-----------------------------------------------------------+

The C<Splitter> is an L<XML::Filter::DocSplitter> by default, and the
C<Merger> is an L<XML::Filter::Merger> by default.  The line that
bypasses the "Stage_1 ..." filter pipeline is used for all events that
do not occur in a record.  All events that occur in a record pass
through the filter pipeline.

=head2 Example

Here's a quick little filter to uppercase text content:

    package My::Filter::Uc;

    use vars qw( @ISA );
    @ISA = qw( XML::SAX::Base );

    use XML::SAX::Base;

    sub characters {
        my $self = shift;
        my ( $data ) = @_;
        $data->{Data} = uc $data->{Data};
        $self->SUPER::characters( @_ );
    }

And here's a little machine that uses it:

    $m = Pipeline(
        ByRecord( "My::Filter::Uc" ),
        \$out,
    );

When fed a document like:

    <root> a
        <rec>b</rec> c
        <rec>d</rec> e
        <rec>f</rec> g
    </root>

the output looks like:

    <root> a
        <rec>B</rec> c
        <rec>C</rec> e
        <rec>D</rec> g
    </root>

and the My::Filter::Uc got three sets of events like:

    start_document
    start_element: <rec>
    characters:    'b'
    end_element:   </rec>
    end_document

    start_document
    start_element: <rec>
    characters:    'd'
    end_element:   </rec>
    end_document

    start_document
    start_element: <rec>
    characters:   'f'
    end_element:   </rec>
    end_document

=head1 NAME

XML::SAX::ByRecord - Record oriented processing of (data) documents

=head1 METHODS

=over

=item new

    my $d = XML::SAX::ByRecord->new( @channels, \%options );

Longhand for calling the ByRecord function exported by XML::SAX::Machines.

=back

=head1 CREDIT

Proposed by Matt Sergeant, with advise by Kip Hampton and Robin Berjon.

=head1 Writing an aggregator.

To be written.  Pretty much just that C<start_manifold_processing> and
C<end_manifold_processing> need to be provided.  See L<XML::Filter::Merger>
and it's source code for a starter.

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
