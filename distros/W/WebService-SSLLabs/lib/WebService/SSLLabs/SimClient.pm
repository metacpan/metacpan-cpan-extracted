package WebService::SSLLabs::SimClient;

use strict;
use warnings;

our $VERSION = '0.28';

sub new {
    my ( $class, $json ) = @_;
    my $self = $json;
    bless $self, $class;
    return $self;
}

sub id {
    my ($self) = @_;
    return $self->{id};
}

sub name {
    my ($self) = @_;
    return $self->{name};
}

sub platform {
    my ($self) = @_;
    return $self->{platform};
}

sub version {
    my ($self) = @_;
    return $self->{version};
}

sub is_reference {
    my ($self) = @_;
    return $self->{isReference} ? 1 : 0;
}

1;
__END__

=head1 NAME

WebService::SSLLabs::SimClient - SimClient object

=head1 VERSION

Version 0.28

=head1 SUBROUTINES/METHODS

=head2 new

a new C<WebService::SSLLabs::SimClient> object, accepts a hash ref as it's parameter.

=head2 id

unique client ID (integer)

=head2 name

text.

=head2 platform

text.

=head2 version

text.

=head2 is_reference

true if the browser is considered representative of modern browsers, false otherwise. This flag does not correlate to client's capabilities, but is used by SSL Labs to determine if a particular configuration is effective. For example, to track Forward Secrecy support, we mark several representative browsers as "modern" and then test to see if they succeed in negotiating a FS suite. Just as an illustration, modern browsers are currently Chrome, Firefox (not ESR versions), IE/Win7, and Safari.

=head1 DIAGNOSTICS

None

=head1 CONFIGURATION AND ENVIRONMENT

WebService::SSLLabs::SimClient requires no configuration files or environment variables.

=head1 DEPENDENCIES

WebService::SSLLabs::SimClient requires no non-core modules

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

    perldoc WebService::SSLLabs::SimClient


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
