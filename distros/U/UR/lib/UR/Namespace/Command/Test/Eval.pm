
package UR::Namespace::Command::Test::Eval;

use strict;
use warnings;
use UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Namespace::Command::Base',
    has => [
        bare_args => {
            is_optional => 1,
            is_many => 1,
            shell_args_position => 1
        }
    ]
);


sub help_brief {
    "Evaluate a string of Perl source";
}

sub help_synopsis {
    return <<'EOS';
ur test eval 'print "hello\n"' 
ur test eval 'print "hello\n"' 'print "goodbye\n"'
ur test eval 'print "Testing in  the " . \$self->namespace_name . " namespace.\n"'
EOS
}

sub help_detail {
    return <<EOS;
This command is for testing and debugging.  It simply eval's the Perl
source supplied on the command line, after using the current namespace.

A \$self object is in scope representing the current context.
EOS
}

sub execute {
    my $self = shift;
    for my $src ($self->bare_args) {
        eval "use Data::Dumper; use YAML; no strict; no warnings; \n" . $src;
        if ($@) {
            print STDERR "EXCEPTION:\n$@";
        }
    }
    return 1;
}

1;
