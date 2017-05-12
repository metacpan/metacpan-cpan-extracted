package perfSONAR_PS::EventTypeEquivalenceHandler;

=head1 NAME

perfSONAR_PS::Request - A module that provides an object to interact with for
each client request.

=head1 DESCRIPTION

This module is to be treated as an object representing a request from a user.
The object can be used to get the users request in DOM format as well as set
and send the response.

=head1 SYNOPSIS

=head1 DETAILS

=head1 API
=cut

use strict;
use warnings;

use perfSONAR_PS::Common;
use Log::Log4perl qw(get_logger :nowarn);

our $VERSION = 0.09;

use fields 'EVENT_TYPES', 'LOGGER';

=head2 new ($package)
    The 'call' argument is the resonse from HTTP::Daemon->accept(). The request
    is the actual http request from the user. In general, it can be obtained
    from the call variable specified above using the '->get_request' function.
    If it is unspecified, new will try to obtain the request from $call
    directly.
=cut
sub new {
    my ($package) = @_;

    my $self = fields::new($package);

    $self->{LOGGER} = get_logger("perfSONAR_PS::EventTypeEquivalenceHandler");

    $self->{EVENT_TYPES} = ();

    return $self;
}

=head2 addEquivalence ($self, $eventType1, $eventType2)
    This function adds an equivalence between the specified event types.
=cut
sub addEquivalence {
    my ($self, $ev1, $ev2) = @_;

    if (not defined $self->{EVENT_TYPES}->{$ev1} and 
            not defined $self->{EVENT_TYPES}->{$ev2}) {
        my %class = ();
        $class{$ev1} = 1;
        $class{$ev2} = 1;

        $self->{EVENT_TYPES}->{$ev1} = \%class;
        $self->{EVENT_TYPES}->{$ev2} = \%class;
    } elsif (not defined $self->{EVENT_TYPES}->{$ev1}) {
        # ev1 is already in an equivalence class, but not ev2. Thus, we
        # put ev1 into the same equivalence class (array) that ev2 is
        # in and then stick a pointer to that array for ev2.

        $self->{EVENT_TYPES}->{$ev2}->{$ev1} = 1;
        $self->{EVENT_TYPES}->{$ev1} = $self->{EVENT_TYPES}->{$ev2};
    } elsif (not defined $self->{EVENT_TYPES}->{$ev2}) {
        # ev2 is already in an equivalence class, but not ev1. Thus, we
        # put ev2 into the same equivalence class (array) that ev1 is
        # in and then stick a pointer to that array for ev1.

        $self->{EVENT_TYPES}->{$ev1}->{$ev2} = 1;
        $self->{EVENT_TYPES}->{$ev2} = $self->{EVENT_TYPES}->{$ev1};
    } else {
        # here, both ev1 and ev2 are in equivalence classes. Therefore,
        # we go through and create a new equivalence class containing
        # all the elements in ev1s class and ev2s class and then update
        # all the elements in the new class to point at the new class.

        my %new_class = ();

        foreach my $ev (keys %{ $self->{EVENT_TYPES}->{$ev1} }) {
            $new_class{$ev} = 1;
        }

        foreach my $ev (keys %{ $self->{EVENT_TYPES}->{$ev2} }) {
            $new_class{$ev} = 1;
        }

        foreach my $ev (keys %new_class) {
            $self->{EVENT_TYPES}->{$ev} = \%new_class;
        }
    }

    return;
}

=head2 matchEventTypes ($self, \@eventTypes1, \@eventTypes2)
    This function takes two arrays of event types and returns the semantic
    'join' of the event types. E.g. if an eventType in array1 and an
    equivalent eventType is in array2, both eventTypes will appear in the
    returned array.
=cut
sub matchEventTypes {
    my ($self, $evs1, $evs2) = @_;

    my %matches = ();

    foreach my $ev1 (@{ $evs1 }) {
        next if (defined $matches{$ev1});

        foreach my $ev2 (@{ $evs2 }) {
            print "'$ev1' - '$ev2'\n";
            if ($ev1 eq $ev2) {
                $matches{$ev1} = 1;
                $matches{$ev2} = 1;
                next;
            }

            if ($self->{EVENT_TYPES}->{$ev1}) {
                if ($self->{EVENT_TYPES}->{$ev1}->{$ev2}) {
                    $matches{$ev1} = 1;
                    $matches{$ev2} = 1;
                }
            }
        }
    }

    my @matches = keys %matches;

    return \@matches;
}

=head2 lookupEquivalence ($self, $eventType)
    This function returns the list of eventTypes that are equivalent to the
    specified eventType. This will include the eventType specified.
=cut
sub lookupEquivalence {
    my ($self, $ev) = @_;

    return if (not defined $self->{EVENT_TYPES}->{$ev});

    my @class = keys %{ $self->{EVENT_TYPES}->{$ev} };

    return \@class;
}

1;

=head1 SEE ALSO

L<Log::Log4perl>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.  Bugs,
feature requests, and improvements can be directed here:

https://bugs.internet2.edu/jira/browse/PSPS

=head1 VERSION

$Id:$

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2008, Internet2 and the University of Delaware

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
