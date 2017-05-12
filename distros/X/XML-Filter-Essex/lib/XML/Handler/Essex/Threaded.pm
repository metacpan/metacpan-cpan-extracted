package XML::Handler::Essex::Threaded;

$VERSION = 0.000_1;

=head1 NAME

XML::Handler::Essex::Threaded - Threading support for perls >= 5.8.0

=head1 SYNOPSIS

=head1 DESCRIPTION

Loaded only if XML::Handler::Essex detects that threads.pm is loaded

=cut

@ISA = qw( XML::Handler::Essex );

use strict;

use threads::shared;

warn "Essex: threads enabled\n";

sub DESTROY {
    my $self = shift;
    return unless $self->{IsChild};
    warn "Essex $self: DESTROYing parent\n" if debugging;
    {
        lock @{$self->{Events}};
        my @event : shared = ( SEPPUKU );
        @{$self->{Events}} = ( \@event );
        threads::shared::cond_signal( @{$self->{Events}} );
    }
    warn "Essex $self: waiting for child to exit\n" if debugging;
    lock @{$self->{Results}};
    until ( @{$self->{Results}} ) {
        warn "Essex $self: cond_wait on Results\n" if debugging;
        threads::shared::cond_wait( @{$self->{Results}} );
    }
    warn "Essex $self: child exited\n" if debugging;
}

# This is design to have the parent block until the child finishes
# handling the event.  This is because the child (and especially filters
# downstream of the child) are likely to be non-threadsafe.  So we only
# allow the child to run when there's an event to process, and we block
# until it is finish.
sub _start_child {
    my $self = shift;

    warn "Essex $self: starting child thread\n" if debugging;

    # the = [] is to give threads::shared something to chew on that
    # won't make it throw up.
    # We pass the type of the event or
    # result in other variables because they don't need to be shared
    # and sharing them can break bless()ing.
    my @events: shared;
    my @results: shared;
    $self->{Events}  = \@events;
    $self->{Results} = \@results;

    # The BOD sync loop in threaded_execute will send us a thread started
    # "result".  Ignore it, other than to sync on it.
    lock @{$self->{Results}};
    $self->{Thread} = threads->create(
        $self->can( "threaded_execute" ),
        $self
    );
    warn "Essex $self: waiting for child thread to start\n" if debugging;
    until ( @{$self->{Results}} ) {
        warn "Essex $self: cond_wait on Results\n" if debugging;
        threads::shared::cond_wait( @{$self->{Results}} );
    }
    @{$self->{Results}} = ();

    warn "Essex $self: child thread started\n" if debugging;
}


## This next sub works around a limitation in 5.8.0's share() that
## seems to prevent me from using it; I get core dumps when I try.
## TODO: try again with 5.8.0.
sub _r_share {
    my $t = reftype $_[0];

    return if ( tied $_[0] or "" ) eq "threads::shared::tie";

    unless ( $t ) {
        my $foo: shared = $_[0];
        $_[0] = $foo;
    }
    elsif ( $t eq "HASH" ) {
        _r_share( $_ )
            for values %{$_[0]};
        my %foo: shared = %{$_[0]};
        $_[0] = \%foo;
    }
    elsif ( $t eq "ARRAY" ) {
        my @foo: shared = map _r_share( $_ ), @{$_[0]};
        $_[0] = \@foo;
    }
    elsif ( $t eq "SCALAR" ) {
        my $foo: shared = ${$_[0]};
        $_[0] = \$foo;
    }
    else {
        Carp::confess "Essex: can't share $t";
    }
}


sub _send_event_to_child {
    my $self = shift;

    $self->_start_child unless $self->{Thread};

    {
        lock @{$self->{Events}};
        for ( @{$self->{PendingEvents}}, \@_ ) {
            _r_share( $_->[1] );
            my @event: shared = @$_;

            warn "Essex $self: sending $event[0] => CHILD \n" if debugging;

            push @{$self->{Events}}, \@event;
        }
        @{$self->{PendingEvents}} = ();
        warn "Essex $self: signalling Events\n" if debugging;
        threads::shared::cond_signal( @{$self->{Events}} );
    } # unlock

    # Receive result from child.
    warn "Essex $self: waiting for result from child\n" if debugging;
    lock @{$self->{Results}};
    until (@{$self->{Results}} ) {
        warn "Essex $self: cond_wait on Results\n" if debugging;
        threads::shared::cond_wait( @{$self->{Results}} );
    }

    my ( $result_type, $result );
    do {
        ( $result_type, $result ) = (
            shift( @{$self->{Results}} ),
            shift( @{$self->{Results}} ),
        );

        warn "Essex $self: ",
            @{$self->{Results}} ? "ignoring" : "got",
            " $result_type result ",
            defined $result ? "'$result'" : "undef",
            " from child\n" if debugging;

    } while @{$self->{Results}};

    $result_type eq "exception"
        ? die $result
        : return $result;
}


sub _send_result_to_parent {
    my $self = shift;

    return unless defined $self->{PendingResultType};

    warn "Essex $self:   sending PARENT <= $self->{PendingResultType} result ",
        defined $self->{PendingResult} ? "'$self->{PendingResult}'" : "undef",
        "\n" if debugging;

    lock @{$self->{Results}};

    _r_share( $self->{PendingResult} );
    push @{$self->{Results}}, @{$self}{qw( PendingResultType PendingResult)};
    @$self{"PendingResultType","PendingResult"} = ();

    warn "Essex $self:   signalling Results\n" if debugging;
    threads::shared::cond_signal( @{$self->{Results}} );
}


# NOTE: returns \@event, whereas _send_event_to_child takes @event.
# This is to speed the queue fudging that threaded_execute does on
# start_document.
sub _recv_event_from_parent {
    my $self = shift;

    my $event;

    die EOD . "\n"
        if $self->{PendingResultType} eq "end_document";

    warn "Essex $self:   getting event from parent\n" if debugging;
    lock @{$self->{Events}};

    # only send a result if there's one to send and there are no
    # events waiting.
    # TODO when and if we allow multiple events to stack up:
    # If there are events waiting, then we need to
    # wait until the last event to send the result.
    $self->_send_result_to_parent;
#            if defined $self->{PendingResultType};# && ! @{$self->{Events}};

    # We don't block if there're already events; this is used
    # at start_document because the execute routine scans the input
    # until it sees the start_document, then queues up a new
    # set_document_locator and start_document.
    until ( @{$self->{Events}} ) {
        warn "Essex $self:   cond_wait on Events\n" if debugging;
        threads::shared::cond_wait( @{$self->{Events}} );
    }

    ## TODO: Lock Events?  The parent should not be running now,
    ## it should be waiting for results.

    return $self->SUPER::_recv_event_from_parent;
}

# Result handling:
#
# We track the event just received so threaded_execute() can tell what
# to do when the main routine exits or throws an exception.  If it was
#
# We don't know if execute() actually does anything, or if it will do
# anything if entered a second time, so we need to return the
# result here.
#
# BOD notes.  We wait for the BOD here and not in _recv_event_from_parent
# because we can't be sure that main() will ever call _recv_event_from_parent.
# It might throw an exception or return a result instead.  This has the
# side effect of making it seem like (to the programmer) the child thread
# is respawned each start_document() event: main() will not be entered until
# after the BOD is sent, and that's sent in start_document().  Whether or
# not that's good or bad depends on what's happening in main(), but it's
# a necessary implementation detail.  It also reserves the right to actually
# implement threading that way one day, either as an option for the caller
# or due to some shift in perl's threading implementation.
sub threaded_execute {
    my $self = shift;

    $self->{IsChild};
    threads->self->detach;

    # This thread only exits if it gets an undefined eventtype.  This is
    # to avoid the extreme cost of starting a thread on every document if
    # the caller is handling a series of documents.
    my $pending_end_document_result = "Essex: default end_document result";
    $self->{PendingResultType} =
        $self->{PendingResult} = "thread started";

EXECUTE:
    while (1) {
        while (1) {  # Wait for BOD.
            if ( $self->{PendingResultType} eq "end_document" ) {
                $self->{PendingResultType} = "end_document again";
                $self->{PendingResult} = $pending_end_document_result;
                $pending_end_document_result
                    = "Essex: default end_document result";
            }

            my $event = eval { $self->_recv_event_from_parent };

            unless ( defined $event ) {
                if ( $@ eq EOD . "\n" ) {
                    lock @{$self->{Events}};
                    shift @{$self->{Events}};
                }
                elsif ( $@ eq BOD . "\n") {
                    lock @{$self->{Events}};
                    shift @{$self->{Events}};
                    last;
                }
                elsif ( $@ eq SEPPUKU . "\n") {
                    last EXECUTE;
                }
                else {
                    die $@;
                }
            }

        }

        $pending_end_document_result = "Essex: default end_document result";

        eval {
            my $event;

            undef $pending_end_document_result;
            warn "Essex $self:  running execute()\n" if debugging;
            my $r = $self->SUPER::execute( @_ );
            warn "Essex $self:  execute() exited with ",
                defined $r ? "'$r'" : "undef",
                "\n"
                if debugging;

            $pending_end_document_result = $r;
            1;
        } or do {
            warn "Essex $self:  execute() exited with exception $@\n"
                if debugging;
            if ( $@ eq EOD  . "\n") {
                lock @{$self->{Events}};
                shift @{$self->{Events}};
            }
            elsif ( $@ eq SEPPUKU . "\n") {
                last;
            }
            else {
                $self->{PendingResultType} = "exception";
                $self->{PendingResult} = $@;
            }
        };
    }

    $self->{PendingResultType} = 
        $self->{PendingResult} = SEPPUKU;
    $self->_send_result_to_parent;
}

# Hopefully, this handles inline set_document_locator events relatively
# gracefully, by queueing them up until the next event arrives.  This is
# necessary because set_document_locator events can arrive *before* the
# start_document, and we need to wait for the next event to see whether
# to insert the BOD before the set_document_locator.  This is all so that
# the initial set_document_locator event(s) will arrive before the
# start_document event in the main() routine, given that we need to
# send the BOD psuedo event in case the main() routine is still running.
sub set_document_locator {
    push @{shift->{PendingEvents}}, [ "set_document_locator", @_ ];
    return "Essex: document locator queued";
}


sub start_document {
    my $self = shift;

    unshift @{$self->{PendingEvents}}, [ BOD ];
    $self->SUPER::start_document( @_ );
}


sub end_document {
    my $self = shift;
    ## Must send EOD after the end_document so that we get the end_document
    ## result back first otherwise it would be lost because
    ## _recv_event_from_parent does not send results back if there are any
    ## other events in the queue.  If this were not so, we could add a hack
    ## here to queue up both end_document and EOD at once.
    my $r = _send_event_to_child( $self, "end_document", @_ );

    my @event: shared = ( EOD );
    lock @{$self->{Events}};
    push @{$self->{Events}}, \@event;
    threads::shared::cond_signal( @{$self->{Events}} );

    return $r;
}


=head1 LIMITATIONS

=head1 COPYRIGHT

    Copyright 2002, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, oir GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
=head1 LIMITATIONS

=head1 COPYRIGHT

    Copyright 2003, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, oir GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
