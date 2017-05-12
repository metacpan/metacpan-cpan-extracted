package UR::Value::View::Default::Text;
use strict;
use warnings;
use UR;

class UR::Value::View::Default::Text {
    is => 'UR::Object::View::Default::Text',
};

sub _generate_content {
    my $self = shift;
    my $subject = $self->subject;
    return unless ($subject);
    my $name = $subject->__display_name__;
    return $name;
}

1;
