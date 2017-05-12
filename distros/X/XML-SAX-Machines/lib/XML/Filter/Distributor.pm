package XML::Filter::Distributor;
{
  $XML::Filter::Distributor::VERSION = '0.46';
}
# ABSTRACT: Multipass processing of documents


use XML::SAX::Base;

@ISA = qw( XML::SAX::Base );


@EXPORT_OK = qw( Distributor );

use strict;
use Carp;
use XML::SAX::EventMethodMaker qw( sax_event_names missing_methods compile_methods );


sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = bless {}, $class;

    $self->{Channels} = [];

    for ( @_ ) {
        push @{$self->{Channels}}, $_;
    }

    return $self;
}


sub set_handlers {
    my $self = shift;
    @{$self->{Channels}} = map { { Handler => $_ } } @_;
}


sub set_handler {
    shift()->set_handlers( @_ );
}


sub _buffer {
    my $self = shift;
    push @{$self->{BUFFER}}, [ @_ ];
}

sub set_aggregator {
    my $self = shift;
    $self->{Aggregator} = shift;
}


sub get_aggregator {
    my $self = shift;

    return $self->{Aggregator};
}


sub _change_channels {
    my $self = shift;

    my ( $desired_channel ) = @_;
    $desired_channel = $self->{CurChannelNum} + 1
        unless defined $desired_channel;
    $desired_channel = undef
        if $desired_channel < 0 || $desired_channel > $#{$self->{Channels}};

    ## Mess with XML::SAX::Base's internals a bit (ugh).
    ## TODO: Get less messy when the X::S::B in CVS makes it in to the
    ## real world.
    $self->{Methods} = {};
    $self->{Handler} = undef;

    if ( defined $desired_channel ) {
        $self->{CurChannel} = $self->{Channels}->[$desired_channel];
        $self->{$_} = $self->{CurChannel}->{$_}
            for keys %{$self->{CurChannel}};
    }

    $self->{CurChannelNum} = $desired_channel;
    return $desired_channel;
}


sub _replay {
    my $self = shift;

    my $r;
    for ( @{$self->{BUFFER}} ) {
        my $event = shift @$_;
        ## This is ugly, must be a faster way, too tired to think of one.
        my $meth = "SUPER::$event";
        $self->$meth( @$_ );
        unshift @$_, $event;
    }

    return $r;
}


sub start_document {
    my $self = shift;

    @{$self->{BUFFER}} = ();
    $self->_buffer( "start_document", @_ );

    $self->_change_channels( 0 );

    my $aggie = $self->get_aggregator;
    $aggie->start_manifold_document( @_ )
        if $aggie && $aggie->can( "start_manifold_document" );

    return $self->SUPER::start_document( @_ );
}


sub end_document {
    my $self = shift;

    $self->_buffer( "end_document", @_ );

    $self->SUPER::end_document( @_ );

    $self->_replay
        while $self->_change_channels;
    
    @{$self->{BUFFER}} = ();

    my $aggie = $self->get_aggregator;
    return $aggie->end_manifold_document( @_ )
        if $aggie && $aggie->can( "end_manifold_document" );

    return ;
}

compile_methods __PACKAGE__, <<'TPL_END', missing_methods __PACKAGE__, sax_event_names ;
sub <EVENT> {
    my $self = shift;
    $self->_buffer( "<EVENT>", @_ );
    return $self->SUPER::<EVENT>( @_ );
}
TPL_END





1;

__END__

=pod

=head1 NAME

XML::Filter::Distributor - Multipass processing of documents

=head1 VERSION

version 0.46

=head1 SYNOPSIS

    ## See XML::SAX::Manifold for an easier way to use this filter.

    use XML::SAX::Machines qw( Machine ) ;

    ## See the wondrous ASCII ART below for help visualizing this
    ## XML::SAX::Manifold makes this a lot easier.
    my $m = Machine(
        [ Intake => "XML::Filter::Distributor" => qw( V TOC Body ) ],
            [ V      => "My::Validator" ],
            [ TOC    => "My::TOCExtractor" => qw( Merger ) ],
            [ Body   => "My::BodyMasseuse" => qw( Merger ) ],
        [ Merger => "XML::Filter::Merger" => qw( Output ) ],
        [ Output => \*STDOUT ],
    );

    ## Let the distributor coordinate with the merger.
    ## XML::SAX::Manifold does this for you.
    $m->Intake->set_aggregator( $m->Merger );

    $m->parse_file( "foo" );

=head1 DESCRIPTION

XML::Filter::Distributor is a SAX filter that allows "multipass" processing
of a document by sending the document through several channels of SAX
processors one channel at a time.  A channel may be a single SAX
processor or a machine like a pipeline (see L<XML::SAX::Pipeline>).

This can be used to send the source document through one entire
processing chain before beginning the next one, for instance if the
first channel is a validator or linter that throws exceptions on error.

It can also be used to run the document through multiple processing
chains and glue all of the chains' output documents back together with
something like XML::Filter::Merger.  The SYNOPSIS does both.

This differs from L<XML::Filter::SAXT> in that the channels are
prioritized and each channel receives all events for a document before
the next channel receives any events.  XML::Filter::Distributor buffers all
events while feeding them to the highest priority channel
(C<$processor1> in the synopsis), and replays them for each lower
priority channel one at a time.

The event flow for the example in the SYNOPSIS would look like, with the
numbers next to the connection arrow indicating when the document's
events flow along that arrow.

                            +-------------+
                         +->| Validator   |
                       1/   +-------------+
                       /
          1   +-------+ 2   +--------------+ 2    +--------+      
 upstream ----| Dist. |---->| TOCExtractor |--*-->| Merger |-> STDOUT
              +-------+     +--------------+ /    +--------+   
                       \3                   /3
                        \   +--------------+
                         +->| BodyMasseuse |
                            +--------------+                         |

Here's the timing of the event flows:

   1: upstream -> Dist ->  Validator
   2:             Dist -> TOCExtractorc -> Merger -> STDOUT
   3:             Dist -> BodyMassseuse -> Merger -> STDOUT

When the document arrives from upstream, the events all arrive during time
period 1 and are buffered and also passed through processor 1.  After all
events have been received (as indicated by an C<end_document> event from
upstream), all events are then played back through processor 2, and then
through processor 3.

=head1 NAME

XML::Filter::Distributor - Multipass processing of documents

=head1 METHODS

=over

=item new

    my $d = XML::Filter::Distributor->new(
        { Handler => $h1 },
        { Handler => $h2 },
        ...
    );

A channel may be any SAX machine, frequently they are pipelines.

=item set_handlers

    $p->set_handlers( $handler1, $handler2 );

Provided for compatability with other SAX processors, use set_handlers
instead.

=item set_handler

Provided for compatability with other SAX processors, use set_handlers
instead.

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
