
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

package Weasel::Widgets::HTML::Button;


use strict;
use warnings;

use Moose;
use Weasel::WidgetHandlers qw/ register_widget_handler /;

extends 'Weasel::Widgets::HTML::Input';

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




1;
