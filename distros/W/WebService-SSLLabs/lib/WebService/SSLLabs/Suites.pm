package WebService::SSLLabs::Suites;

use strict;
use warnings;
use WebService::SSLLabs::Suite();

our $VERSION = '0.33';

sub new {
    my ( $class, $json ) = @_;
    my $self = $json;
    bless $self, $class;
    if ( defined $self->{list} ) {
        my @suites = @{ $self->{list} };
        $self->{list} = [];
        foreach my $suite (@suites) {
            push @{ $self->{list} }, WebService::SSLLabs::Suite->new($suite);
        }
    }
    else {
        $self->{list} = [];
    }
    return $self;
}

sub list {
    my ($self) = @_;
    return @{ $self->{list} };
}

sub preference {
    my ($self) = @_;
    return $self->{preference} ? 1 : 0;
}

1;
__END__

=head1 NAME

WebService::SSLLabs::Suites - Suites object

=head1 VERSION

Version 0.33

=head1 SUBROUTINES/METHODS

=head2 new

a new C<WebService::SSLLabs::Suites> object, accepts a hash ref as it's parameter.

=head2 list

list of L<Suite|WebService::SSLLabs::Suite> objects

=head2 preference

true if the server actively selects cipher suites; if null, we were not able to determine if the server has a preference

=head1 DIAGNOSTICS

None

=head1 CONFIGURATION AND ENVIRONMENT

WebService::SSLLabs::Suites requires no configuration files or environment variables.

=head1 DEPENDENCIES

WebService::SSLLabs::Suites requires no non-core modules

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

    perldoc WebService::SSLLabs::Suites


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
