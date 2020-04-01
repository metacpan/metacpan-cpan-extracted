package WebService::SSLLabs::Host;

use strict;
use warnings;
use WebService::SSLLabs::Endpoint();

our $VERSION = '0.33';

sub new {
    my ( $class, $json ) = @_;
    my $self = $json;
    if ( defined $self->{endpoints} ) {
        my @endpoints = @{ $self->{endpoints} };
        $self->{endpoints} = [];
        foreach my $endpoint (@endpoints) {
            push @{ $self->{endpoints} },
              WebService::SSLLabs::Endpoint->new($endpoint);
        }
    }
    else {
        $self->{endpoints} = [];
    }
    bless $self, $class;
    return $self;
}

sub ready {
    my ($self) = @_;
    if ( $self->status() =~ /^READY$/smxi ) {
        return $self;
    }
    else {
        return;
    }
}

sub complete {
    my ($self) = @_;
    if ( $self->status() =~ /^READY|ERROR$/smxi ) {
        return $self;
    }
    else {
        return;
    }
}

sub eta {
    my ($self) = @_;
    my $host_eta;
    foreach my $endpoint ( $self->endpoints() ) {
        if (   ( defined $endpoint->eta() )
            && ( $endpoint->eta() =~ /^\d+$/smx ) )
        {
            if ( !defined $host_eta ) {
                $host_eta = $endpoint->eta();
            }
            if ( $endpoint->eta() >= $host_eta ) {
                $host_eta = $endpoint->eta();
            }
        }
    }
    return $host_eta;
}

sub status {
    my ($self) = @_;
    return $self->{status};
}

sub status_message {
    my ($self) = @_;
    return $self->{statusMessage};
}

sub endpoints {
    my ($self) = @_;
    return @{ $self->{endpoints} };
}

sub host {
    my ($self) = @_;
    return $self->{host};
}

sub port {
    my ($self) = @_;
    return $self->{port};
}

sub start_time {
    my ($self) = @_;
    return $self->{startTime};
}

sub criteria_version {
    my ($self) = @_;
    return $self->{criteriaVersion};
}

sub engine_version {
    my ($self) = @_;
    return $self->{engineVersion};
}

sub is_public {
    my ($self) = @_;
    return $self->{isPublic} ? 1 : 0;
}

sub protocol {
    my ($self) = @_;
    return $self->{protocol};
}

sub test_time {
    my ($self) = @_;
    return $self->{testTime};
}

1;
__END__

=head1 NAME

WebService::SSLLabs::Host - Host object

=head1 VERSION

Version 0.33

=head1 SUBROUTINES/METHODS

=head2 new

a new C<WebService::SSLLabs::Host> object, accepts a hash ref as it's parameter.

=head2 complete

will return the current C<WebService::SSLLabs::Host> object if L<status|WebService::SSLLabs::Host/"status"> is READY or ERROR. Otherwise it will return undef
assessment status; possible values: DNS, ERROR, IN_PROGRESS, and READY.

=head2 ready

will return the current C<WebService::SSLLabs::Host> object if L<status|WebService::SSLLabs::Host/"status"> is equal to READY.  Otherwise it will return undef.

=head2 eta

will return the highest of any of the L<eta|WebService::SSLLabs::Endpoint/"eta"> values from the available L<endpoints|WebService::SSLLabs::Host/"endpoints">.

=head2 host 

assessment host, which can be a hostname or an IP address

=head2 port

assessment port (e.g., 443)

=head2 protocol

protocol (e.g., HTTP)

=head2 is_public

true if this assessment publicly available (listed on the SSL Labs assessment boards)

=head2 status 

assessment status; possible values: DNS, ERROR, IN_PROGRESS, and READY.

=head2 status_message

status message in English. When status is ERROR, this field will contain an error message.

=head2 start_time

assessment starting time, in milliseconds since 1970

=head2 test_time

assessment completion time, in milliseconds since 1970

=head2 engine_version

assessment engine version (e.g., "1.0.180")

=head2 criteria_version

grading criteria version (e.g., "2009")

=head2 cache_expiry_time

when will the assessment results expire from the cache (typically set only for assessment with errors; otherwise the results stay in the cache for as long as there's sufficient room)

=head2 endpoints

list of L<Endpoint|WebService::SSLLabs::Endpoint> objects

=head2 cert_hostnames

the list of certificate hostnames collected from the certificates seen during assessment. The hostnames may not be valid. This field is available only if the server certificate doesn't match the requested hostname. In that case, this field saves you some time as you don't have to inspect the certificates yourself to find out what valid hostnames might be.

=head1 DIAGNOSTICS

None

=head1 CONFIGURATION AND ENVIRONMENT

WebService::SSLLabs::Host requires no configuration files or environment variables.

=head1 DEPENDENCIES

WebService::SSLLabs::Host requires no non-core modules

=head1 INCOMPATIBILITIES

None reported

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-net-ssllabs at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-SSLLabs>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

David Dick, C<< <ddick at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::SSLLabs::Host


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-SSLLabs>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-SSLLabs>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-SSLLabs>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-SSLLabs/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Ivan Ristic and the team at L<https://www.qualys.com> for providing the service at L<https://www.ssllabs.com>

POD was extracted from the API help at L<https://github.com/ssllabs/ssllabs-scan/blob/stable/ssllabs-api-docs.md>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 David Dick.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
