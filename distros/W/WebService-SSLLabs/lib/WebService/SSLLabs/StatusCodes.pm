package WebService::SSLLabs::StatusCodes;

use strict;
use warnings;

our $VERSION = '0.28';

sub new {
    my ( $class, $json ) = @_;
    my $self = $json;
    bless $self, $class;
    return $self;
}

sub status_details {
    my ($self) = @_;
    return %{ $self->{statusDetails} };
}

1;
__END__

=head1 NAME

WebService::SSLLabs::StatusCodes - StatusCodes object

=head1 VERSION

Version 0.28

=head1 SUBROUTINES/METHODS

=head2 new

a new C<WebService::SSLLabs::StatusCodes> object, accepts a hash ref as it's parameter.

=head2 status_details

a hash containing all status details codes and the corresponding English translations. Please note that, once in use, the codes will not change, whereas the translations may change at any time.

=head1 DIAGNOSTICS

None

=head1 CONFIGURATION AND ENVIRONMENT

WebService::SSLLabs::StatusCodes requires no configuration files or environment variables.

=head1 DEPENDENCIES

WebService::SSLLabs::StatusCodes requires no non-core modules

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

    perldoc WebService::SSLLabs::StatusCodes


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
