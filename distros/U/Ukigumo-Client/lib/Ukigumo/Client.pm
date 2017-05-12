package Ukigumo::Client;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.36';

use Carp ();
use Capture::Tiny;
use Encode::Locale;
use Encode;
use File::Spec;
use File::Path qw(mkpath);
use LWP::UserAgent;
use English '-no_match_vars';
use HTTP::Request::Common qw(POST);
use JSON qw(decode_json);
use File::Temp;
use File::HomeDir;
use Cwd;
use Scope::Guard;

use Ukigumo::Constants;
use Ukigumo::Client::CommandRunner;
use Ukigumo::Client::Executor::Command;
use Ukigumo::Client::Logger;
use Ukigumo::Client::YamlConfig;
use Ukigumo::Helper qw(normalize_path);
use Ukigumo::Logger;

use Mouse;

has 'workdir' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    lazy => 1,
    default => sub {
        my $self = shift;
        File::Spec->catdir( File::HomeDir->my_home, '.ukigumo', 'work')
    },
);
has 'project' => (
    is => 'rw',
    isa => 'Str',
    default => sub {
        my $self = shift;
        my $proj = $self->repository;
           $proj =~ s/\.git$//;
           $proj =~ s!.+\/!!;
           $proj || '-';
    },
    lazy => 1,
);
has 'logfh' => (
    is => 'ro',
    default => sub { File::Temp->new(UNLINK => 1) }
);
has 'server_url' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);
has 'user_agent' => (
    is       => 'ro',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $ua = LWP::UserAgent->new(
            agent => "ukigumo-client/$Ukigumo::Client::VERSION" );
        $ua->env_proxy;
        $ua;
    },
);

has quiet => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

# components
has 'vc' => (
    is       => 'ro',
    required => 1,
    handles => [qw(get_revision branch repository)],
);
has 'executor' => (
    is       => 'ro',
    required => 1,
);
has 'notifiers' => (
    is       => 'rw',
    default  => sub { +[ ] },
);

has 'compare_url' => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);
has 'repository_owner' => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);
has 'repository_name' => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

# for VC log
has vc_log => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        chomp(my $orig_revision    = $self->orig_revision);
        chomp(my $current_revision = $self->current_revision);
        join '', $self->vc->get_log($orig_revision, $current_revision);
    },
);
has current_revision => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->vc->get_revision();
    },
);
has orig_revision => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->vc->get_revision();
    },
);

has 'elapsed_time_sec' => (
    is      => 'rw',
    isa     => 'Maybe[Int]',
    default => 0,
);

has 'logger' => (
    is      => 'ro',
    isa     => 'Ukigumo::Client::Logger',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Ukigumo::Client::Logger->new(
            logfh  => $self->logfh,
            branch => $self->branch,
            quiet  => $self->quiet,
        );
    },
);

no Mouse;

sub push_notifier {
    my $self = shift;
    push @{$self->notifiers}, @_;
}

sub run {
    my $self = shift;

    # Back to original directory, after work.
    my $orig_cwd = Cwd::getcwd();
    my $guard = Scope::Guard->new(
        sub { chdir $orig_cwd }
    );

    my $workdir = File::Spec->catdir( $self->workdir, normalize_path($self->project), normalize_path($self->branch) );

    $self->logger->infof("ukigumo-client $VERSION");
    $self->logger->infof("start testing : " . $self->vc->description());
    $self->logger->infof("working directory : " . $workdir);

    {
        mkpath($workdir);
        unless (chdir($workdir)) {
            $self->reflect_result(STATUS_FAIL);
            die "Cannot chdir(@{[ $workdir ]}): $!";
        }

        $self->logger->infof('run vc : ' . ref $self->vc);
        chomp(my $orig_revision = $self->orig_revision);

        $self->vc->update($self, $workdir);
        chomp(my $current_revision = $self->current_revision);

        if ($self->vc->skip_if_unmodified && $orig_revision eq $current_revision) {
            $self->logger->infof('skip testing');
            return;
        }

        my $conf = Ukigumo::Client::YamlConfig->new(c => $self);

        local %ENV = %ENV;
        $conf->apply_environment_variables;

        $self->project($conf->project_name || $self->project);

        $self->push_notifier(@{$conf->notifiers});

        my $repository_owner = $self->repository_owner;
        my $repository_name  = $self->repository_name;

        for my $notify (grep { ref $_ eq NOTIFIER_GITHUBSTATUSES } @{$self->notifiers}) {
            $notify->send($self, STATUS_PENDING, '', '', $current_revision, $repository_owner, $repository_name);
        }

        my $command_runner = Ukigumo::Client::CommandRunner->new(c => $self, config => $conf);

        $command_runner->run('before_install');
        $command_runner->run('install');
        $command_runner->run('before_script');

        my $executor = defined($conf->script) ? Ukigumo::Client::Executor::Command->new(command => $conf->script)
                                              : $self->executor;

        $self->logger->infof('run executor : ' . ref $executor);
        my $status = $executor->run($self);
        $self->logger->infof('finished testing : ' . $status);

        $command_runner->run('after_script');

        $self->reflect_result($status);
    }

    $self->logger->infof("end testing");
}

sub report_timeout {
    my ($self, $log_filename) = @_;

    $self->elapsed_time_sec(undef);
    $self->reflect_result(STATUS_TIMEOUT, $log_filename);
}

sub reflect_result {
    my ($self, $status, $log_filename) = @_;

    my ($report_url, $last_status) = $self->send_to_server($status, $log_filename);

    $self->logger->infof("sending notification: @{[ $self->branch ]}, $status");

    my $repository_owner = $self->repository_owner;
    my $repository_name  = $self->repository_name;

    for my $notify (@{$self->notifiers}) {
        $notify->send($self, $status, $last_status, $report_url, $self->current_revision, $repository_owner, $repository_name);
    }
}

sub send_to_server {
    my ($self, $status, $log_filename) = @_;

    my $server_url = $self->server_url;
       $server_url =~ s!/$!!g;

    $self->logger->infof("sending result to server at $server_url (status: $status)");

    my $ua = $self->user_agent();

    # flush log file before send it
    $self->logfh->flush();

    my $req =
        POST $server_url . '/api/v1/report/add',
        Content_Type => 'form-data',
        Content => [
            project  => $self->project,
            branch   => $self->branch,
            repo     => $self->repository,
            revision => substr($self->current_revision, 0, 10),
            status   => $status,
            vc_log   => $self->vc_log,
            body     => [$log_filename || $self->logfh->filename],
            compare_url => $self->compare_url,
            elapsed_time_sec => $self->elapsed_time_sec,
        ];
    my $res = $ua->request($req);
    $res->is_success or die "Cannot send a report to @{[ $self->server_url ]}/api/v1/report/add:\n" . $res->as_string;
    my $dat = eval { decode_json($res->decoded_content) } || $res->decoded_content . " : $@";
    $self->logger->infof("report url: $dat->{report}->{url}");
    my $report_url = $dat->{report}->{url} or die "Cannot get report url";
    return ($report_url, $dat->{report}->{last_status});
}

sub tee {
    my ($self, $command) = @_;
    $self->logger->infof("command: $command");
    my ($out) = Capture::Tiny::tee_merged {
        ( $EUID, $EGID ) = ( $UID, $GID );
        my $begin_time = time;
        system $command;
        $self->elapsed_time_sec($self->elapsed_time_sec + time - $begin_time);
    };
    $out = Encode::encode("console_in", Encode::decode("console_out", $out));

    print {$self->logfh} $out;
    return $?;
}

1;
__END__

=encoding utf8

=for stopwords infof warnf

=head1 NAME

Ukigumo::Client - Client library for Ukigumo

=head1 SYNOPSIS

    use Ukigumo::Client;
    use Ukigumo::Client::VC::Git;
    use Ukigumo::Client::Executor::Auto;
    use Ukigumo::Client::Notify::Debug;
    use Ukigumo::Client::Notify::Ikachan;

    my $app = Ukigumo::Client->new(
        vc   => Ukigumo::Client::VC::Git->new(
            branch     => $branch,
            repository => $repo,
        ),
        executor   => Ukigumo::Client::Executor::Perl->new(),
        server_url => $server_url,
        project    => $project,
    );
    $app->push_notifier(
        Ukigumo::Client::Notify::Ikachan->new(
            url     => $ikachan_url,
            channel => $ikachan_channel,
        )
    );
    $app->run();

=head1 DESCRIPTION

Ukigumo::Client is client library for Ukigumo.

=head1 ATTRIBUTES

=over 4

=item C<workdir>

Working directory for the code. It's C<$ENV{HOME}/.ukigumo/work/$project/$branch> by default.

=item C<project>

Its' project name. This is a mandatory parameter.

=item C<logfh>

Log file handle. It's read only parameter.

=item C<server_url>

URL of the Ukigumo server. It's required.

=item C<user_agent>

instance of L<LWP::UserAgent>. It's have a default value.

=item C<vc>

This is a version controller object. It's normally Ukigumo::Client::VC::*. But you can write your own class.

VC::* objects should have a following methods:

    get_revision branch repository

=item C<executor>

This is a test executor object. It's normally Ukigumo::Client::Executor::*. But you can write your own class.

=item C<notifiers>

This is a arrayref of notifier object. It's normally Ukigumo::Client::Notify::*. But you can write your own class.

=item C<compare_url>

URL to compare differences between range of commitments.

=item C<elapsed_time_sec>

Elapsed time as seconds about executing tests.

=back

=head1 METHODS

=over 4

=item $client->push_notifier($notifier : Ukigumo::Client::Notify)

push a notifier object to $client->notifiers.

=item $client->run()

Run a test context.

=item $client->send_to_server($status: Int)

Send a notification to the sever.

=item reflect_result($status: Int)

Send a notification to the server and notify via registered notifier.

=item $client->tee($command: Str)

This method runs C<< $command >> and tee the output of the STDOUT/STDERR to the C<logfh>.

I<Return>: exit code by the C<< $command >>.

=item $client->logger->infof($message)

Print C<< $message >> as INFO and write to the C<logfh>.

=item $client->logger->warnf($message)

Print C<< $message >> as WARN and write to the C<logfh>.

=item $client->report_timeout()

This method always sends FAIL report to server and notifies to each notifiers.

=back

=head1 CONFIGURATION

If C<.ukigumo.yml> file is on the project root, L<Ukigumo::Client> loads that file and applies the settings that are written in it.

Please see also L<ukigumo.yml.pod>.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

L<Ukigumo::Server>, L<Ukigumo|https://github.com/ukigumo/>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
