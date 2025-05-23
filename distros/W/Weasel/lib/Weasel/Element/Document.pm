
=head1 NAME

Weasel::Element::Document - Weasel Document (root) element

=head1 VERSION

version 0.32

=head1 SYNOPSIS



=head1 DESCRIPTION

The root element of the document tag tree: corresponds with the C<html>
tag of the HTML document.

=cut

=head1 DEPENDENCIES



=cut

package Weasel::Element::Document 0.32;

use strict;
use warnings;

use Moose;
extends 'Weasel::Element';
use namespace::autoclean;

=head1 ATTRIBUTES

=over

=item _id

Internal. Contains the reference to the in-browser element.

=cut

has '+_id' => (required => 0,
               default => '/html');

=back

=cut

=head1 SUBROUTINES/METHODS

=cut

=head1 AUTHOR

Erik Huelsmann

=head1 CONTRIBUTORS

Erik Huelsmann
Yves Lavoie

=head1 MAINTAINERS

Erik Huelsmann

=head1 BUGS AND LIMITATIONS

Bugs can be filed in the GitHub issue tracker for the Weasel project:
 https://github.com/perl-weasel/weasel/issues

=head1 SOURCE

The source code repository for Weasel is at
 https://github.com/perl-weasel/weasel

=head1 SUPPORT

Community support is available through
L<perl-weasel@googlegroups.com|mailto:perl-weasel@googlegroups.com>.

=head1 LICENSE AND COPYRIGHT

 (C) 2016-2023  Erik Huelsmann

Licensed under the same terms as Perl.

=cut

__PACKAGE__->meta->make_immutable;

1;
