package XML::Filter::Tee;
{
  $XML::Filter::Tee::VERSION = '0.46';
}
# ABSTRACT: Send SAX events to multiple processor, with switching



use strict;
use Carp;
use XML::SAX::Base;
use XML::SAX::EventMethodMaker qw( compile_methods sax_event_names );


sub new {
    my $proto = shift;
    my $self = bless {}, ref $proto || $proto;

    $self->{DisabledHandlers} = [];

    $self->set_handlers( @_ );

    return $self;
}



sub set_handlers {
    my $self = shift;

    $self->{Handlers} = [
        map XML::SAX::Base->new(
            ref $_ eq "HASH"
                ? %$_
                : { Handler => $_ }
        ), @_
    ];
}



sub disable_handlers {
    my $self = shift;

    croak "Can only disable one handler" if @_ > 1;
    my ( $which ) = @_;

    my $hs = $self->{Handlers};

    if ( ref $which ) {
        for my $i ( 0..$#$hs ) {
            next unless $hs->[$i];
            if ( $hs->[$i] == $which ) {
                $self->{DisabledHandlers}->[$i] = $hs->[$i];
                $hs->[$i] = undef;
            }
        }
    }
    elsif ( $which =~ /^\d+(?!\n)$/ ) {
        $self->{DisabledHandlers}->[$which] = $hs;
        $self->{Handlers}->[$which] = undef;
    }
    else {
        for my $i ( 0..$#$hs ) {
            next unless $hs->[$i];
            if ( $hs->[$i]->{Name} eq $which ) {
                $self->{DisabledHandlers}->[$i] = $hs->[$i];
                $hs->[$i] = undef;
            }
        }
    }
}


sub enable_handlers {
    my $self = shift;

    croak "Can only enable one handler" if @_ > 1;
    my ( $which ) = @_;

    my $hs = $self->{Handlers};

    if ( ref $which ) {
        for my $i ( 0..$#$hs ) {
            next unless $hs->[$i];
            if ( $hs->[$i] == $which ) {
                $hs->[$i] = $self->{DisabledHandlers}->[$i];
                $self->{DisabledHandlers}->[$i] = undef;
            }
        }
    }
    elsif ( $which =~ /^\d+(?!\n)$/ ) {
        $hs->[$which] = $self->{DisabledHandlers}->[$which];
        $self->{DisabledHandlers}->[$which] = undef;
    }
    else {
        for my $i ( 0..$#$hs ) {
            next unless $hs->[$i];
            if ( $hs->[$i]->{Name} eq $which ) {
                $hs->[$i] = $self->{DisabledHandlers}->[$i];
                $self->{DisabledHandlers}->[$i] = undef;
            }
        }
    }
}


compile_methods( __PACKAGE__, <<'FOO', sax_event_names );
sub <EVENT> {
    my $self = shift;
    for ( @{$self->{Handlers}} ) {
        next unless defined $_;
        $_-><EVENT>( @_ );
    }
}
FOO



1;

__END__

=pod

=head1 NAME

XML::Filter::Tee - Send SAX events to multiple processor, with switching

=head1 VERSION

version 0.46

=head1 SYNOPSIS

    my $t = XML::Filter::Tee->new(
        { Handler => $h0 },
        { Handler => $h1 },
        { Handler => $h2 },
        ...
    );

    ## Altering the handlers list:
    $t->set_handlers( $h0, $h1, $h2, $h3 );

    ## Controlling flow to a handler by number and by reference:
    $t->disable_handler( 0 );
    $t->enable_handler( 0 );

    $t->disable_handler( $h0 );
    $t->enable_handler( $h0 );

    ## Use in a SAX machine (though see L<XML::SAX::Pipeline> and
    ## L<XML::SAX::Tap> for a more convenient way to build a machine
    ## like this):
    my $m = Machine(
        [ Intake => "XML::Filter::Tee" => qw( A B ) ],
        [ A      => ">>log.xml" ],
        [ B      => \*OUTPUT ],
    );

=head1 DESCRIPTION

XML::Filter::Tee is a SAX filter that passes each event it receives on to a
list of downstream handlers.

It's like L<XML::Filter::SAXT> in that the events are not buffered; each
event is sent first to the tap, and then to the branch (this is
different from L<XML::SAX::Dispatcher>, which buffers the events).
Unlike L<XML::Filter::SAXT>, it allows it's list of handlers to be
reconfigured (via L</set_handlers>) and it allows control over which
handlers are allowed to receive events.  These features are designed to
make XML::Filter::Tee instances more useful with SAX machines, but they to
add some overhead relative to XML::Filter::SAXT.

The events are not copied, since they may be data structures that are
difficult or impossibly to copy properly, like parts of a C-based DOM
implementation.  This means that the handlers must not alter the events
or later handlers will see the alterations.

=head1 NAME

XML::Filter::Tee - Send SAX events to multiple processor, with switching

=head1 METHODS

=over

=item new

    my $t = XML::Filter::Tee->new(
        { Handler => $h0 },
        { Handler => $h1 },
        { Handler => $h2 },
        ...
    );

=item set_handlers

    $t->set_handlers( $h0, $h1, $h2 );
    $t->set_handlers( {
            Handler => $h0,
        },
        {
            Handler => $h1,
        },
    );

Replaces the current list of handlers with new ones.

Can also name handlers to make enabling/disabling them by name easier:

    $m->set_handlers( {
            Handler => $validator,
            Name    => "Validator",
        },
        {
            Handler => $outputer,
        },
    );

    $m->disable_handler( "Validator" );

=item disable_handler

    $t->disable_handler( 0 );            ## By location
    $t->disable_handler( "Validator" );  ## By name
    $t->disable_handler( $h0 );          ## By reference

Stops sending events to the indicated handler.

=item enable_handler

    $t->enable_handler( 0 );            ## By location
    $t->enable_handler( "Validator" );  ## By name
    $t->enable_handler( $h0 );          ## By reference

Stops sending events to the indicated handler.

=back

=head1 AUTHOR

    Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

    Copyright 2002, Barrie Slaymaker, All Rights Reserved

You may use this module under the terms of the Artistic, GNU Public, or
BSD licenses, as you choose.

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
