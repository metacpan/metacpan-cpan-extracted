
package UR::Namespace::Command::List::Modules;

use strict;
use warnings;
use UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => "UR::Namespace::Command::RunsOnModulesInTree",
);

sub help_description { "List all modules in the current namespace." }

sub for_each_module_file
{
    my $self = shift;
    my $module = shift;
    print "$module\n";
}

1;

