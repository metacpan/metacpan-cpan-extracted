package Ukigumo::Agent::Manager;
use strict;
use warnings;
use utf8;
use Ukigumo::Agent::Cleaner qw/cleanup_old_branch_dir/;
use Ukigumo::Client;
use Ukigumo::Client::VC::Git;
use Ukigumo::Client::Executor::Perl;
use Ukigumo::Helper qw/normalize_path/;
use Ukigumo::Logger;
use Coro;
use Coro::AnyEvent;
use POSIX qw/SIGTERM SIGKILL/;
use File::Spec;
use Carp ();

use Mouse;

has 'config' => (
    is       => 'rw',
    isa      => 'HashRef',
    lazy     => 1,
    default  => sub { +{} },
);

has 'work_dir' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { shift->config->{work_dir} // File::Spec->tmpdir },
);

has 'server_url' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { shift->config->{server_url} },
);

has 'timeout' => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => sub { shift->config->{timeout} // 0 },
);

has 'ignore_github_tags' => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { shift->config->{ignore_github_tags} // 0 },
);

has 'force_git_url' => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { shift->config->{force_git_url} // 0 },
);

has 'max_children' => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => sub { shift->config->{max_children} // 1 },
);

has 'cleanup_cycle' => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => sub { shift->config->{cleanup_cycle} || 0 },
);

has 'job_queue' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { +[] },
);

has 'children' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { +{} },
);

has 'logger' => (
    is      => 'ro',
    isa     => 'Ukigumo::Logger',
    lazy    => 1,
    default => sub { Ukigumo::Logger->new },
);

no Mouse;

sub count_children {
    my $self = shift;
    0+(keys %{$self->children});
}

sub push_job {
    my ($self, $job) = @_;
    push @{$self->{job_queue}}, $job;
}

sub pop_job {
    my ($self, $job) = @_;
    pop @{$self->{job_queue}};
}

sub run_job {
    my ($self, $args) = @_;
    Carp::croak("Missing args") unless $args;

    my $repository = $args->{repository} || die;
    my $branch     = $args->{branch} || die;

    my $vc = Ukigumo::Client::VC::Git->new(
        branch     => $branch,
        repository => $repository,
    );
    my $client = Ukigumo::Client->new(
        workdir     => $self->work_dir,
        vc          => $vc,
        executor    => Ukigumo::Client::Executor::Perl->new(),
        server_url  => $self->server_url,
        compare_url => $args->{compare_url} || '',
        repository_owner => $args->{repository_owner} || '',
        repository_name  => $args->{repository_name} || '',
    );

    my $client_log_filename = $client->logfh->filename;

    my $timeout_timer;

    my $pid = fork();
    if (!defined $pid) {
        die "Cannot fork: $!";
    }

    if ($pid) {
        $self->logger->infof("Spawned $pid");
        $self->{children}->{$pid} = +{
            child => AE::child($pid, unblock_sub {
                my ($pid, $status) = @_;

                undef $timeout_timer;

                # Process has terminated because it was timeout
                if ($status == SIGTERM) {
                    Coro::AnyEvent::sleep 5;
                    if (kill 0, $pid) {
                        # Process is still alive
                        kill SIGTERM, $pid;
                        Coro::AnyEvent::sleep 5;
                        if (kill 0, $pid) {
                            # The last resort
                            kill SIGKILL, $pid;
                        }
                    }
                    $self->logger->warnf("[child] timeout");
                    eval { $client->report_timeout($client_log_filename) };
                    if ($@) {
                        $self->logger->warnf("[child] fail on sending timeout report: $@");
                    }
                }

                $self->logger->infof("[child exit] pid: $pid, status: $status");
                delete $self->{children}->{$pid};

                if ($self->count_children < $self->max_children && @{$self->job_queue} > 0) {
                    $self->logger->infof("[child exit] run new job");
                    $self->run_job($self->pop_job);
                } else {
                    $self->_take_a_break();
                }
            }),
            job => $args,
            start => time(),
        };
        my $timeout = $self->timeout;
        if ($timeout > 0) {
            $timeout_timer = AE::timer $timeout, 0, sub {
                kill SIGTERM, $pid;
            };
        }
    } else {
        eval { $client->run() };
        $self->logger->warnf("[child] error: $@") if $@;

        if (my $cleanup_cycle = $self->cleanup_cycle) {
            my $project_dir = File::Spec->catfile($client->workdir, normalize_path($client->project));
            cleanup_old_branch_dir($project_dir, $cleanup_cycle);
        }

        $self->logger->infof("[child] finished to work");
        exit;
    }
}

sub register_job {
    my ($self, $params) = @_;

    if ($self->count_children < $self->max_children) {
        # run job.
        $self->run_job($params);
    } else {
        $self->push_job($params);
    }
}

sub _take_a_break {
    my ($self) = @_;
    $self->logger->infof("[child exit] There is no jobs. sleep...");
}

1;
