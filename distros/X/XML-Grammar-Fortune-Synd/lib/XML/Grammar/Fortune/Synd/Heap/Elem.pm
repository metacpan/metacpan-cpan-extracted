package XML::Grammar::Fortune::Synd::Heap::Elem;

use strict;
use warnings;

=head1 NAME

XML::Grammar::Fortune::Synd::Heap::Elem - heap element class for
XML::Grammar::Fortune::Synd. For internal use.

=head1 VERSION

Version 0.0211

=cut

use base 'Class::Accessor';

our $VERSION = '0.0211';

__PACKAGE__->mk_accessors(qw(
    date
    id
    idx
    file
    ));

# "All problems in computer science can be solved by
# adding another level of indirection;"
# -- http://en.wikipedia.org/wiki/Abstraction_layer
sub cmp
{
    my ($self, $other) = @_;
    return
    (
        ($self->date()->compare($other->date()))
            ||
        ($self->idx() <=> $other->idx())
    )
    ;
}

1;


=head1 SYNOPSIS

For internal use.

=head1 FUNCTIONS

=head2 cmp()

Internal use.

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-grammar-fortune-synd at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Grammar-Fortune-Synd>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Grammar::Fortune::Synd


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Grammar-Fortune-Synd>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-Grammar-Fortune-Synd>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-Grammar-Fortune-Synd>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Grammar-Fortune-Synd>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT/X11 License

L<http://www.opensource.org/licenses/mit-license.php>

=cut

