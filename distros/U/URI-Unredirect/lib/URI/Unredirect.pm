package URI::Unredirect;

use strict;
use warnings;

use URI ();
use URI::Escape ();

our $VERSION = '0.01';
$VERSION = eval $VERSION;

sub URI::unredirect {
    my ($uri) = @_;

    my $str = $uri->as_string;

    my $http_idx = rindex $str, 'http';
    return $uri unless $http_idx > 0;

    $str = substr $str, $http_idx;

    my $amp_idx = index $str, '&';
    if ($amp_idx > 0) {
        $str = substr $str, 0, $amp_idx;
    }

    $str = URI::Escape::uri_unescape($str);

    if ($str =~ m{( https?://\S* [^.,;'">\s\)\]] )}x) {
        return URI->new($1);
    }

    return $uri;
}


1;

__END__

=head1 NAME

URI::Unredirect - Remove obvious redirects from a C<URI>

=head1 SYNOPSIS

    use URI;
    use URI::Unredirect;

    my $uri = URI->new('http://example.com/r?u=http%3A%2F%2Fexample.net');
    $uri = $uri->unredirect;  # http://example.net/

=head1 DESCRIPTION

C<URI::Unredirect> enables the removal of obvious redirects from a C<URI>
without making any network requests.

It is a port of the 'remove redirects' javascript bookmarklet.

It adds the following method to the C<URI> namespace:

=head1 METHODS

=head2 unredirect

    $uri = $uri->unredirect

Removes obvious redirects and returns the resulting C<URI> object.

For efficiency reasons, if the C<URI> is unchanged, a reference to the
original is returned instead of a copy.

=head1 SEE ALSO

L<URI>

L<https://www.squarefree.com/bookmarklets/pagelinks.html#remove_redirects>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=URI-Unredirect>. I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URI::Unredirect

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/uri-unredirect>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/URI-Unredirect>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/URI-Unredirect>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=URI-Unredirect>

=item * Search CPAN

L<http://search.cpan.org/dist/URI-Unredirect>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
