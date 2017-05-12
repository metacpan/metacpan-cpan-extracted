package Ukigumo::Client::CommandRunner;
use strict;
use warnings;
use Ukigumo::Constants;

use Mouse;

has c => (
    is       => 'ro',
    isa      => 'Ukigumo::Client',
    required => 1,
);

has config => (
    is       => 'ro',
    isa      => 'Ukigumo::Client::YamlConfig',
    required => 1,
);

no Mouse;

sub run {
    my ($self, $phase) = @_;
    my $c = $self->c;
    my $logger = $c->logger;

    my $extra_command;
    if ($phase eq 'install') {
        $extra_command = $self->_decide_install_cmd();
    }

    for my $cmd (@{$extra_command || $self->config->$phase || []}) {
        $logger->infof("[${phase}] $cmd");
        my $begin_time = time;

        unless (system($cmd) == 0) {
            $logger->warnf("Failure in ${phase}: $cmd");
            $c->reflect_result(STATUS_FAIL);
            die "Failure in ${phase}: $cmd\n";
        }

        $c->elapsed_time_sec($c->elapsed_time_sec + time - $begin_time);
    }

    return 1;
}

sub _decide_install_cmd {
    my ($self) = @_;

    if (my $install = $self->config->install) {
        return ref $install ? $install : [$install];
    }

    if (-f 'Makefile.PL' || -f 'cpanfile' || -f 'Build.PL') {
        return ['cpanm --notest --installdeps .'];
    }

    return;
}

1;
