package WebService::SSLLabs::Chain;

use strict;
use warnings;
use WebService::SSLLabs::ChainCert();

our $VERSION = '0.30';

sub new {
    my ( $class, $json ) = @_;
    my $self = $json;
    bless $self, $class;
    if ( defined $self->{certs} ) {
        my @certs = @{ $self->{certs} };
        $self->{certs} = [];
        foreach my $cert (@certs) {
            push @{ $self->{certs} },
              WebService::SSLLabs::ChainCert->new($cert);
        }
    }
    else {
        $self->{certs} = [];
    }
    return $self;
}

sub certs {
    my ($self) = @_;
    return @{ $self->{certs} };
}

sub issues {
    my ($self) = @_;
    return $self->{issues};
}

1;
__END__

=head1 NAME

WebService::SSLLabs::Chain - Chain object

=head1 VERSION

Version 0.30

=head1 SUBROUTINES/METHODS

=head2 new

a new C<WebService::SSLLabs::Chain> object, accepts a hash ref as it's parameter.

=head2 certs

a list of L<ChainCert|WebService::SSLLabs::ChainCert> objects, representing the chain certificates in the order in which they were retrieved from the server

=head2 issues

a number of flags that describe the chain and the problems it has:

=over 2

=item bit 0 (1) - unused

=item bit 1 (2) - incomplete chain (set only when we were able to build a chain by adding missing intermediate certificates from external sources)

=item bit 2 (4) - chain contains unrelated or duplicate certificates (i.e., certificates that are not part of the same chain)

=item bit 3 (8) - the certificates form a chain (trusted or not), but the order is incorrect

=item bit 4 (16) - contains a self-signed root certificate (not set for self-signed leafs)

=item bit 5 (32) - the certificates form a chain (if we added external certificates, bit 1 will be set), but we could not validate it. If the leaf was trusted, that means that we built a different chain we trusted.

=back

=head1 DIAGNOSTICS

None

=head1 CONFIGURATION AND ENVIRONMENT

WebService::SSLLabs::Chain requires no configuration files or environment variables.

=head1 DEPENDENCIES

WebService::SSLLabs::Chain requires no non-core modules

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

    perldoc WebService::SSLLabs::Chain


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
