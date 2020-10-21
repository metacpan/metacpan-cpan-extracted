package WebService::Blogger::AtomReading;
our $VERSION = '0.23';
use warnings;
use strict;

use Moose::Role;

sub get_link_href_by_rel {
    ## Returns "href" attribute of the first element of type "link" in
    ## given tree generated from Atom entry using XML::Simple.
    my $self = shift;
    my ($tree, $rel_value) = @_;

    foreach my $link (@{ $tree->{link} }) {
        return $link->{href} if ref($rel_value) && $link->{rel} =~ $rel_value
                                || $link->{rel} eq $rel_value;
    }
}

1;

__END__

=head1 NAME

WebService::Blogger::AtomReading - Role providing common methods for
reading Atom entries.

=head1 SYNOPSIS

Not designed to be used independently. Please see
L<WebService::Blogger> for usage instructions for the package.

=head1 METHODS

=over 1

=item get_link_href_by_rel($tree, $rel_value)

Returns value of "href" attribute of "link" node with given "rel"
attribute value. First argument is data structure resulting from
parsing Atom feed with XML::Simple.

=back

=head1 AUTHOR

Kedar Warriner, C<< <kedar at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-google-api-blogger at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Blogger>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Blogger

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Blogger>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Blogger>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Blogger>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Blogger/>

=back

=head1 ACKNOWLEDGEMENTS

 Many thanks to:
  - Egor Shipovalov who wrote the original version of this module
  - Everyone involved with CPAN.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Kedar Warriner.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
