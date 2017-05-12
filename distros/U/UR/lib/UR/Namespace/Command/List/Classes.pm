
package UR::Namespace::Command::List::Classes;

use strict;
use warnings;
use UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => "UR::Namespace::Command::RunsOnModulesInTree",
);

sub help_description { "List all classes in the current namespace." }

sub for_each_class_object
{
    my $self = shift;
    my $class = shift;
    print $class->class_name,"\n";
}

1;

