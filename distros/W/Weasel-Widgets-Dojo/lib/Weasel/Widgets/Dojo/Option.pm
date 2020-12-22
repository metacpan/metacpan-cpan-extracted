
package Weasel::Widgets::Dojo::Option;

use strict;
use warnings;

use Moose;
use Weasel::Widgets::HTML::Selectable;
extends 'Weasel::Widgets::HTML::Selectable';

use Weasel::WidgetHandlers qw/ register_widget_handler /;

register_widget_handler(__PACKAGE__, 'Dojo',
                        tag_name => 'tr',
                        attributes => {
                            role => 'option',
                        });


sub _option_popup {
    my ($self) = @_;

    # Note, this assumes there are no pop-ups nested in the DOM,
    # which from experimentation I believe to be true at this point
    my $popup = $self->find('ancestor::*[@dijitpopupparent]');

    return $popup;
}

sub click {
    my ($self) = @_;
    my $popup = $self->_option_popup;

    my $id = $popup->get_attribute('dijitpopupparent');
    my $selector = $self->find("//*[\@id='$id']");
    if (! $popup->is_displayed) {
        $selector->click; # pop up the selector
        $self->session->wait_for(
          # Wait till popup opens
          sub {
            my $class = $selector->get_attribute('class');
            return scalar( grep { $_ eq 'dijitHasDropDownOpen' }
                           split /\s+/, $class);
        });
    }
    # Click the text, which masks $self under Firefox
    $self->find("//*[\@id='" . $self->get_attribute('id') . "_text']")->SUPER::click;
    $self->session->wait_for(
      # Wait till popup closes
      sub {
        my $class = $selector->get_attribute('class');
        return !scalar( grep { $_ eq 'dijitHasDropDownOpen' }
                       split /\s+/, $class) ;
    });

    return;
}

sub selected {
    my ($self, $new_value) = @_;

    if (defined $new_value) {
        my $selected = $self->get_attribute('aria-selected') eq 'true';
        if ($new_value && ! $selected) {
            $self->click; # select
        }
        elsif (! $new_value && $selected) {
            $self->click; # unselect
        }
    }

    return $self->get_attribute('aria-selected') eq 'true';
}


1;
