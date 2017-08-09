package testcases::Base::XAOBase;
use strict;
use XAO::Utils;

use base qw(testcases::Base::base);

###############################################################################

sub test_set_root {
    my $self=shift;

    use XAO::Base;

    my $homedir=$XAO::Base::homedir;

    XAO::Base::set_root('/tmp');
    $self->assert($XAO::Base::homedir eq '/tmp',
                  "Error setting up root using set_root, got '$XAO::Base::homedir' (1)");

    $self->assert($XAO::Base::projectsdir eq '/tmp/projects',
                  "Error setting up root using set_root, got '$XAO::Base::projectsdir' (2)");

    XAO::Base::set_root($homedir);
    $self->assert($XAO::Base::homedir eq $homedir,
                  "Error setting up root using set_root, got '$XAO::Base::homedir' (3)");
}

###############################################################################

sub test_import {
    my $self=shift;

    use XAO::Base qw($homedir $projectsdir);

    $self->assert(defined $homedir,
                  "Imported homedir is not defined");

    $self->assert(($homedir =~ /testcases\/testroot/) ? 1 : 0,
                  "Imported homedir is wrong");
}

###############################################################################

sub test_catch_stdout {
    my $self=shift;

    my $expect="Foo\n";

    $self->catch_stdout();

    print $expect;

    my $got=$self->get_stdout();

    $self->assert($got eq $expect,
        "Mismatch in catch_stdout: got='$got' expect='$expect'");

    $self->catch_stderr();

    print STDERR $expect;

    $got=$self->get_stderr();

    $self->assert($got eq $expect,
        "Mismatch in catch_stderr: got='$got' expect='$expect'");
}

###############################################################################
1;
