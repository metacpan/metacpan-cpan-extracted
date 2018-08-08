package UR::Value::Boolean::View::Default::Text;

use strict;
use warnings;
require UR;
our $VERSION = "0.47"; # UR $VERSION;

class UR::Value::Boolean::View::Default::Text {
  is => 'UR::Object::View::Default::Text'
};


sub _generate_content {
  my $self = shift;
  my $subject = $self->subject();
  return $subject && $subject->id ? "1" : "0";
}

1;
