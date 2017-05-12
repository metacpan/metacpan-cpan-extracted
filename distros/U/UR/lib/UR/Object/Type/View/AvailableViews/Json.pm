package UR::Object::Type::View::AvailableViews::Json;

use strict;
use warnings;

require UR;
our $VERSION = "0.46"; # UR $VERSION;

use UR::Object::Type::View::AvailableViews::Xml;

class UR::Object::Type::View::AvailableViews::Json {
    is => 'UR::Object::View::Default::Json',
    has_constant => [
        perspective => { value => 'available-views' },
    ],
};

sub _jsobj {
    my $self = shift;

    my $subject = $self->subject;
    return unless $subject;

    my $target_class = $subject->class_name;

    my %perspectives = UR::Object::Type::View::AvailableViews::Xml::_find_perspectives($self, $target_class);
    return \%perspectives;
}

1;
