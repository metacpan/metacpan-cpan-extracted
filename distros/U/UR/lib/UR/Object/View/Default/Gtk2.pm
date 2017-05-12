package UR::Object::View::Default::Gtk2;

use strict;
use warnings;
require UR;
our $VERSION = "0.46"; # UR $VERSION;

class UR::Object::View::Default::Gtk2 {
    is => 'UR::Object::View',
    has_constant => [
        perspective => { value => 'default'},
        toolkit => { value => 'gtk2'},
    ],
};

sub _create_widget {
    my $self = shift;
    my $label = Gtk2::Label->new("<new>");
    return $label;
}

sub _update_view_from_subject {
    my $self = shift;
    my $subject = $self->subject();
    my @aspects = $self->aspects;
    my $widget = $self->widget();
    
    my $text = $self->subject_class_name;
    $text .= " with id " . $subject->id if $subject;

    # Don't recurse back into something we're already in the process of showing
    if ($self->_subject_is_used_in_an_encompassing_view()) {
        $text .= " (REUSED ADDR)\n";
    } else {
        $text .= "\n";
        my @sorted_aspects = map { $_->[1] }
                             sort { $a->[0] <=> $b->[0] }
                             map { [ $_->position, $_ ] }
                             @aspects;
        for my $aspect (@sorted_aspects) {
            my $label = $aspect->label;
            $text .= "\n" . $label . ": ";
            if ($subject) {
                my @value = $subject->$label;
                $text .= join(", ", @value);
            }
            else {
                $text .= "-";
            }
        }
    }
    $widget->set_text($text);
    return 1;
}

sub _update_subject_from_view {
    Carp::confess("This widget shouldn't be able to write to the object, it's a label?  How did I get called?");
}

sub _add_aspect {
    shift->_update_view_from_subject;
}

sub _remove_aspect {
    shift->_update_view_from_subject;
}

1;

=pod

=head1 NAME

UR::Object::View::Default::Gtk2 - Gtk2 adaptor for object views

=head1 DESCRIPTION

This class provides code that implements a basic Gtk2 renderer for UR objects.

=head1 SEE ALSO

UR::Object::View, UR::Object

=cut

