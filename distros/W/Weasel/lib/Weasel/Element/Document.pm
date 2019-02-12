
=head1 NAME

Weasel::Element::Document - Weasel Element Document 

=head1 VERSION

0.01

=head1 SYNOPSIS



=head1 DESCRIPTION

=cut

=head1 DEPENDENCIES



=cut

package Weasel::Element::Document;

use strict;
use warnings;

use Moose;
extends 'Weasel::Element';
use namespace::autoclean;

=head1 ATTRIBUTES

=over

=item _id

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

 (C) 2016  Erik Huelsmann

Licensed under the same terms as Perl.

=cut

__PACKAGE__->meta->make_immutable;

1;

