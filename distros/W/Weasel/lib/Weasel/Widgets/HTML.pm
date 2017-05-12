
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

package Weasel::Widgets::HTML;

use strict;
use warnings;


use Weasel::Widgets::HTML::Button; # button, reset, image, submit, BUTTON
use Weasel::Widgets::HTML::Selectable; # checkbox, radio, OPTION
use Weasel::Widgets::HTML::Input; # text, password, <default>
use Weasel::Widgets::HTML::Select;

# No widgets for file inputs and
#  more importantly TEXTAREA, FORM and SELECT

1;
