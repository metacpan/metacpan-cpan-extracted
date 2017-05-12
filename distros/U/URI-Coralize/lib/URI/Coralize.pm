package URI::Coralize;

use strict;
use warnings;

use URI ();

our $VERSION = '0.01';
$VERSION = eval $VERSION;

sub URI::coralize {
    my ($uri) = @_;

    # CoralCDN doesn't proxy secure requests and simply redirects to the
    # requested resource.
    return $uri if 'http' ne $uri->scheme;

    my $host = eval { $uri->host };
    return $uri unless $host;

    # Don't coralize the coralized.
    return $uri if $host =~ m[ (?:^ | \.) nyud.net $]x;

    my $new = $uri->clone;

    if (80 != $uri->port) {
        $host .= '.' . $uri->port;
        $new->port(undef);
    }

    $host .= '.nyud.net';

    $new->host($host);

    return $new;
}


1;

__END__

=head1 NAME

URI::Coralize - Create a C<URI> that uses the CoralCDN

=head1 SYNOPSIS

    use URI;
    use URI::Coralize;

    my $uri = URI->new('http://example.com:8080/test/');
    $uri = $uri->coralize;  # http://example.com.8080.nyud.net/test/

=head1 DESCRIPTION

C<URI::Coralize> allows a C<URI> to be created that will use the Coral
Content Distribution Network (CoralCDN).

It adds the following method to the C<URI> namespace:

=head1 METHODS

=head2 coralize

    $uri = $uri->coralize

Creates a new C<URI> object that directs the request through the CoralCDN.

For efficiency reasons, if the C<URI> is unchanged, a reference to the
original is returned instead of a copy.

=head1 SEE ALSO

L<URI>

L<http://www.coralcdn.org/>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=URI-Coralize>. I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URI::Coralize

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/uri-coralize>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/URI-Coralize>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/URI-Coralize>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=URI-Coralize>

=item * Search CPAN

L<http://search.cpan.org/dist/URI-Coralize>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
