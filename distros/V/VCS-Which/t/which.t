#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Fatal;
use lib qw{t/lib};
use VCS::Which;

new();
capabilities();
which();
uptodate();
wexec();
wlog();
cat();
versions();
pull();
vcs_push();
status();
checkout();
add();

done_testing();

sub new {
    my $vcsw = eval { VCS::Which->new };
    ok !$@, "No error creating" or diag $@;

    $vcsw = eval { VCS::Which->new( dir => '.' ) };
    ok !$@, "No error creating" or diag $@;

    $vcsw = eval { VCS::Which->new( dir => 'Build.PL' ) };
    ok !$@, "No error creating" or diag $@;
}

sub capabilities {
    my $vcsw = eval { VCS::Which->new };

    my %capabilities = $vcsw->capabilities;

    # Only guarentee Blank installed
    ok $capabilities{Blank}, "Blank test VCS installed";

    %capabilities = $vcsw->capabilities('.');

    # Only guarentee Blank installed
    is $capabilities{Blank}{installed}, 0.5, "Blank test VCS installed in .";

    my $capabilities = $vcsw->capabilities('.');

    like $capabilities, qr/^Blank\s+installed\s+versioning$/xms, 'Blak is installed';
}

sub which {
    my $vcsw = eval { VCS::Which->new(dir => 't') };

    my $which = $vcsw->which();
    isa_ok $which, 'VCS::Which::Plugin::Blank';

    $which = $vcsw->which('.');
    isa_ok $which, 'VCS::Which::Plugin::Blank';

    $vcsw->dir(undef);
    eval { $vcsw->which() };
    ok $@, 'Error with no supplied dir';
}

sub uptodate {
    my $vcsw = eval { VCS::Which->new() };

    delete $vcsw->{dir};
    eval { $vcsw->uptodate() };
    my $error = $@;
    like $error, qr/No directory supplied!/, "Errors if no directory set";

    $vcsw->{dir} = 't';
    my $uptodate = $vcsw->uptodate();
    is $uptodate, 1, 'The t directory is up to date';

    {
        no warnings;
        $VCS::Which::Plugin::Blank::uptodate = 0;
    }

    $uptodate = $vcsw->uptodate('t');
    is $uptodate, 1, 'The t directory is up to date (cached)';

    $uptodate = $vcsw->uptodate('.');
    is $uptodate, 0, 'The current directory is not up to date';
}

sub wexec {
    my $vcsw = eval { VCS::Which->new() };

    delete $vcsw->{dir};
    like exception { $vcsw->exec('test') }, qr/No directory supplied!/, 'Error with out a directory';
    ok $vcsw->exec('.', 'test'), 'Exec low level command';

    $vcsw = eval { VCS::Which->new(dir => 't') };
    ok $vcsw->exec('test'), 'Exec low level command';

    like exception { $vcsw->exec() }, qr/Nothing to exec!/, 'Error with nothing to exec';
}

sub wlog {
    my $vcsw = eval { VCS::Which->new() };
    delete $vcsw->{dir};
    like exception { $vcsw->log('test') }, qr/No directory supplied!/, 'Error with out a directory';
    ok $vcsw->log('.'), 'Log "." dir';
    ok $vcsw->log('Build.PL'), 'Log file';

    $vcsw = eval { VCS::Which->new(dir => 't') };
    ok $vcsw->log(), 'Log default dir';
    ok $vcsw->log('other'), 'Log default dir';
}

sub cat {
    my $vcsw = eval { VCS::Which->new() };
    like exception { $vcsw->cat() }, qr/No file supplied!/, 'Error with out a directory';
    ok $vcsw->cat('.'), 'Cat "." dir';
    ok $vcsw->cat('Build.PL'), 'Cat file';

    $vcsw = eval { VCS::Which->new(dir => 't') };
    ok $vcsw->cat(), 'Cat default dir';
    ok $vcsw->cat('other'), 'Cat default dir';
}

sub versions {
    my $vcsw = eval { VCS::Which->new(dir => 't') };

    my @versions = $vcsw->versions('t/which.t');
    is scalar @versions, 0, 'Called versions';

    @versions = $vcsw->versions();
    is scalar @versions, 0, 'Called versions';

    $vcsw->dir(undef);
    eval { $vcsw->versions() };
    ok $@, 'Error with no supplied dir';
}

sub pull {
    my $vcsw = eval { VCS::Which->new(dir => 't') };

    my $pull = $vcsw->pull('t/which.t');
    is $pull, 1, 'Called pull';

    $pull = $vcsw->pull();
    is $pull, 1, 'Called pull';

    $vcsw->dir(undef);
    eval { $vcsw->pull() };
    ok $@, 'Error with no supplied dir';
}

sub vcs_push {
    my $vcsw = eval { VCS::Which->new(dir => 't') };

    my $push = $vcsw->push('t/which.t');
    is $push, 1, 'Called push';

    $push = $vcsw->push();
    is $push, 1, 'Called push';

    $vcsw->dir(undef);
    eval { $vcsw->push() };
    ok $@, 'Error with no supplied dir';
}

sub status {
    my $vcsw = eval { VCS::Which->new(dir => 't') };

    my $status = $vcsw->status('t/which.t');
    is $status, 1, 'Called status';

    $status = $vcsw->status();
    is $status, 1, 'Called status';

    $vcsw->dir(undef);
    eval { $vcsw->status() };
    ok $@, 'Error with no supplied dir';
}

sub checkout {
    my $vcsw = eval { VCS::Which->new(dir => 't') };

    my $checkout = $vcsw->checkout('t/which.t');
    is $checkout, 1, 'Called checkout';

    $checkout = $vcsw->checkout();
    is $checkout, 1, 'Called checkout';

    $vcsw->dir(undef);
    eval { $vcsw->checkout() };
    ok $@, 'Error with no supplied dir';
}

sub add {
    my $vcsw = eval { VCS::Which->new(dir => 't') };

    my $add = $vcsw->add('t/which.t');
    is $add, 1, 'Called add';

    $add = $vcsw->add();
    is $add, 1, 'Called add';

    $vcsw->dir(undef);
    eval { $vcsw->add() };
    ok $@, 'Error with no supplied dir';
}
