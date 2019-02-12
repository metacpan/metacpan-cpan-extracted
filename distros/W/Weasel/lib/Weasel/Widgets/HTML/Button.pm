
=head1 NAME

Weasel::Widgets::HTML::Button - Wrapper for button-like INPUT and BUTTON tags

=head1 VERSION

0.01

=head1 SYNOPSIS

  my $button = $session->page->find('./button');
  # Submit the button's form
  $button->click;

=head1 DESCRIPTION

=cut

=head1 DEPENDENCIES



=cut

package Weasel::Widgets::HTML::Button;


use strict;
use warnings;

use Moose;
use Weasel::WidgetHandlers qw/ register_widget_handler /;

extends 'Weasel::Widgets::HTML::Input';
use namespace::autoclean;

=head1 SUBROUTINES/METHODS

=cut

register_widget_handler(
    __PACKAGE__, 'HTML',
    tag_name => 'input',
    attributes => {
        type => $_
    })
    for (qw/ submit reset button image /);

register_widget_handler(
    __PACKAGE__, 'HTML',
    tag_name => 'button'
    );


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

