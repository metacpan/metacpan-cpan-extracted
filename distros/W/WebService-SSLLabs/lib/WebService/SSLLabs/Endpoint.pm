package WebService::SSLLabs::Endpoint;

use strict;
use warnings;
use WebService::SSLLabs::EndpointDetails();

our $VERSION = '0.33';

sub new {
    my ( $class, $json ) = @_;
    my $self = $json;
    if ( defined $self->{details} ) {
        $self->{details} =
          WebService::SSLLabs::EndpointDetails->new( $self->{details} );
    }
    bless $self, $class;
    return $self;
}

sub ready {
    my ($self) = @_;
    if ( defined $self->{statusMessage}
        && $self->{statusMessage} =~ /^READY$/ismx )
    {
        return $self;
    }
    else {
        return;
    }
}

sub ip_address {
    my ($self) = @_;
    return $self->{ipAddress};
}

sub is_exceptional {
    my ($self) = @_;
    return $self->{isExceptional} ? 1 : 0;
}

sub delegation {
    my ($self) = @_;
    return $self->{delegation};
}

sub has_warnings {
    my ($self) = @_;
    return $self->{hasWarnings} ? 1 : 0;
}

sub grade_trust_ignored {
    my ($self) = @_;
    return $self->{gradeTrustIgnored};
}

sub status_message {
    my ($self) = @_;
    return $self->{statusMessage};
}

sub duration {
    my ($self) = @_;
    return $self->{duration};
}

sub grade {
    my ($self) = @_;
    return $self->{grade};
}

sub eta {
    my ($self) = @_;
    return $self->{eta};
}

sub progress {
    my ($self) = @_;
    return $self->{progress};
}

sub server_name {
    my ($self) = @_;
    return $self->{serverName};
}

sub details {
    my ($self) = @_;
    return $self->{details};
}

1;
__END__

=head1 NAME

WebService::SSLLabs::Endpoint - Endpoint object

=head1 VERSION

Version 0.33

=head1 SUBROUTINES/METHODS

=head2 new

a new C<WebService::SSLLabs::Endpoint> object, accepts a hash ref as it's parameter.

=head2 ready

will return the current C<WebService::SSLLabs::Endpoint> object if L<status|WebService::SSLLabs::Endpoint/"status_message"> is equal to Ready.  Otherwise it will return undef.

=head2 subject

certificate subject

=head2 ip_address

endpoint IP address, in IPv4 or IPv6 format.

=head2 server_name

server name retrieved via reverse DNS

=head2 status_message

assessment status message

=head2 status_details

code of the operation currently in progress

=head2 status_details_message

description of the operation currently in progress

=head2 grade

possible values: A+, A-, A-F, T (no trust) and M (certificate name mismatch)

=head2 grade_trust_ignored

grade (as above), if trust issues are ignored

=head2 has_warnings

if this endpoint has warnings that might affect the score (e.g., get A- instead of A).

=head2 is_exceptional

this flag will be raised when an exceptional configuration is encountered. The SSL Labs test will give such sites an A+.

=head2 progress

assessment progress, which is a value from 0 to 100, and -1 if the assessment has not yet started

=head2 duration

assessment duration, in milliseconds

=head2 eta

estimated time, in seconds, until the completion of the assessment

=head2 delegation

indicates domain name delegation with and without the www prefix

=over 2

=item bit 0 (1) - set for non-prefixed access

=item bit 1 (2) - set for prefixed access

=back

=head2 details

this field contains an L<EndpointDetails|WebService::SSLLabs::EndpointDetails> object. It's not present by default, but can be enabled by using the "all" paramerer to the L<analyze|WebService::SSLLabs/"analyze"> API call.

=head1 DIAGNOSTICS

None

=head1 CONFIGURATION AND ENVIRONMENT

WebService::SSLLabs::Endpoint requires no configuration files or environment variables.

=head1 DEPENDENCIES

WebService::SSLLabs::Endpoint requires no non-core modules

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

    perldoc WebService::SSLLabs::Endpoint


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
