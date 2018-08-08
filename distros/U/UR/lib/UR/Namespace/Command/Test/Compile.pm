
package UR::Namespace::Command::Test::Compile;

use strict;
use warnings;
use UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => "UR::Namespace::Command::RunsOnModulesInTree",
);

sub help_brief {
    "Attempts to compile each module in the namespace in its own process."
}

sub help_synopsis {
    return <<EOS
ur test complie

ur test compile Some::Module Some::Other::Module

ur test complile Some/Module.pm Some/Other/Mod*.pm
EOS
}

sub help_detail {
    return <<EOS
This command runs "perl -c" on each module in a separate process and aggregates results.
Running with --verbose will list specific modules instead of just a summary.

Try "ur test use" for a faster evaluation of whether your software tree is broken. :)
EOS
}

sub for_each_module_file {
    my $self = shift;
    my $module_file = shift;
    my $lib_path = $self->lib_path;
    my @response = `cd $lib_path; perl -I $lib_path -c $module_file 2>&1`;
    if (grep { $_ eq "$module_file syntax OK\n" } @response) {
        print "$module_file syntax OK\n"
    }
    else {
        chomp @response;
        print "$module_file syntax FAILED\n"
            . join("\n\t",@response), "\n";
    }
    return 1;
}

1;

