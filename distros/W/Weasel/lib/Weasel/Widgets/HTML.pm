
=head1 NAME

Weasel::Widgets::HTML - Helper module for bulk-registration of HTML widgets

=head1 VERSION

0.01

=head1 SYNOPSIS

  use Weasel::Widgets::HTML;

  my $button = $session->page->find('//button');
  # $button is now a Weasel::Widgets::HTML::Button instance

=head1 DESCRIPTION


=cut

=head1 DEPENDENCIES



=cut

package Weasel::Widgets::HTML;

use strict;
use warnings;


use Weasel::Widgets::HTML::Button; # button, reset, image, submit, BUTTON
use Weasel::Widgets::HTML::Selectable; # checkbox, radio, OPTION
use Weasel::Widgets::HTML::Input; # text, password, <default>
use Weasel::Widgets::HTML::Select;

# No widgets for file inputs and
#  more importantly TEXTAREA, FORM and SELECT

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

1;

