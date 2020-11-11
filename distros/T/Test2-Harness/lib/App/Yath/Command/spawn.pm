package App::Yath::Command::spawn;
use strict;
use warnings;

our $VERSION = '1.000038';

use App::Yath::Options;

use Time::HiRes qw/sleep time/;
use File::Temp qw/tempfile/;

use Test2::Harness::Util qw/parse_exit/;

use parent 'App::Yath::Command::run';
use Test2::Harness::Util::HashBase;

sub group { 'persist' }

sub summary { "Launch a perl script from the preloaded environment" }
sub cli_args { "[--] path/to/script.pl [options and args]" }

sub description {
    return <<"    EOT";
This will launch the specified script from the preloaded yath process.

NOTE: environment variables are not automatically passed to the spawned
process. You must use -e or -E (see help) to specify what environment variables
you care about.
    EOT
}

option_group {prefix => 'spawn', category => 'spawn options'} => sub {
    option stage => (
        short => 's',
        type => 's',
        description => 'Specify the stage to be used for launching the script',
        long_examples => [ ' foo'],
        short_examples => [ ' foo'],
        default => 'default',
    );

    option copy_env => (
        short => 'e',
        type => 'm',
        description => "Specify environment variables to pass along with their current values, can also use a regex",
        long_examples => [ ' HOME', ' SHELL', ' /PERL_.*/i' ],
        short_examples => [ ' HOME', ' SHELL', ' /PERL_.*/i' ],
    );

    option env_var => (
        field          => 'env_vars',
        short          => 'E',
        type           => 'h',
        long_examples  => [' VAR=VAL'],
        short_examples => ['VAR=VAL', ' VAR=VAL'],
        description    => 'Set environment variables for the spawn',
    );
};

sub read_line {
    my ($fh, $timeout) = @_;

    $timeout //= 300;

    my $start = time;
    while (1) {
        if ($timeout < (time - $start)) {
            my @caller = caller;
            die "Timed out at $caller[1] line $caller[2].\n";
        }
        seek($fh, 0,1) if eof($fh);
        my $out = <$fh> // next;
        chomp($out);
        return $out;
    }
}

# This is here for subclasses
sub queue_spawn {
    my $self = shift;
    my ($args) = @_;

    $self->state->queue_spawn($args);
}

sub run_script { shift @ARGV // die "No script specified" }

sub stage { $_[0]->settings->spawn->stage }

sub env_vars {
    my $self = shift;

    my $settings = $self->settings;

    my $env = {};

    for my $var (@{$settings->spawn->copy_env}) {
        if ($var =~ m{^/(.*)/(\w*)$}s) {
            my ($re, $opts) = ($1, $2);
            my $pattern = length($opts) ? "(?$opts)$re" : $re;
            $env->{$_} = $ENV{$_} for grep { m/$pattern/ } keys %ENV;
        }
        else {
            $env->{$var} = $ENV{$var};
        }
    }

    my $set = $settings->spawn->env_vars;
    $env->{$_} = $set->{$_} for keys %$set;

    return $env;
}

sub set_pname {
    my $self = shift;
    my ($run) = @_;

    $0 = "yath-" . $self->name . " $run " . join (' ', @ARGV);
}

sub pre_process_argv {
    shift @ARGV if @ARGV && $ARGV[0] eq '--';
}

sub sig_handlers { qw/INT TERM HUP QUIT USR1 USR2 STOP WINCH/ }

sub set_sig_handlers {
    my $self = shift;
    my ($wpid) = @_;

    local $@;
    eval { my $s = $_; $SIG{$s} = sub { kill($s, $wpid) } } for $self->sig_handlers;
}

sub clear_sig_handlers {
    my $self = shift;

    local $@;
    eval { my $s = $_; $SIG{$s} = 'DEFAULT' } for $self->sig_handlers;
}

sub pre_exit_hook {}

sub run {
    my $self = shift;

    $self->pre_process_argv;

    my $run = $self->run_script;
    $self->set_pname($run);

    my ($fh, $name) = tempfile(UNLINK => 1);
    close($fh);

    $self->queue_spawn({
        stage    => $self->stage // 'default',
        file     => $run,
        owner    => $$,
        ipcfile  => $name,
        args     => [@ARGV],
        env_vars => $self->env_vars,
    });

    open($fh, '<', $name) or die "Could not open ipcfile: $!";
    my $mpid = read_line($fh);
    my $wpid = read_line($fh);
    my $win  = read_line($fh);

    $self->set_sig_handlers($wpid);

    open(my $wfh, '>>', "/proc/$mpid/fd/$win") or die "Could not open /proc/$wpid/fd/$win: $!";
    $wfh->autoflush(1);
    STDIN->blocking(0);
    while (0 < kill(0, $mpid)) {
        my $line = <STDIN>;
        if (defined $line) {
            print $wfh $line;
        }
        else {
            sleep 0.2;
        }
    }

    $self->clear_sig_handlers();

    my $exit = read_line($fh) // die "Could not get exit code";
    $exit = parse_exit($exit);
    if ($exit->{sig}) {
        print STDERR "Terminated with signal: $exit->{sig}.\n";
        kill($exit->{sig}, $$);
    }

    print STDERR "Exited with code: $exit->{err}.\n" if $exit->{err};

    $self->pre_exit_hook($exit);

    exit($exit->{err});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Command::spawn - Launch a perl script from the preloaded environment

=head1 DESCRIPTION

This will launch the specified script from the preloaded yath process.

NOTE: environment variables are not automatically passed to the spawned
process. You must use -e or -E (see help) to specify what environment variables
you care about.


=head1 USAGE

    $ yath [YATH OPTIONS] spawn [COMMAND OPTIONS]

=head2 YATH OPTIONS

=head3 Developer

=over 4

=item --dev-lib

=item --dev-lib=lib

=item -D

=item -D=lib

=item -Dlib

=item --no-dev-lib

Add paths to @INC before loading ANYTHING. This is what you use if you are developing yath or yath plugins to make sure the yath script finds the local code instead of the installed versions of the same code. You can provide an argument (-Dfoo) to provide a custom path, or you can just use -D without and arg to add lib, blib/lib and blib/arch.

Can be specified multiple times


=back

=head3 Environment

=over 4

=item --persist-dir ARG

=item --persist-dir=ARG

=item --no-persist-dir

Where to find persistence files.


=item --persist-file ARG

=item --persist-file=ARG

=item --pfile ARG

=item --pfile=ARG

=item --no-persist-file

Where to find the persistence file. The default is /{system-tempdir}/project-yath-persist.json. If no project is specified then it will fall back to the current directory. If the current directory is not writable it will default to /tmp/yath-persist.json which limits you to one persistent runner on your system.


=item --project ARG

=item --project=ARG

=item --project-name ARG

=item --project-name=ARG

=item --no-project

This lets you provide a label for your current project/codebase. This is best used in a .yath.rc file. This is necessary for a persistent runner.


=back

=head3 Help and Debugging

=over 4

=item --show-opts

=item --no-show-opts

Exit after showing what yath thinks your options mean


=item --version

=item -V

=item --no-version

Exit after showing a helpful usage message


=back

=head3 Plugins

=over 4

=item --no-scan-plugins

=item --no-no-scan-plugins

Normally yath scans for and loads all App::Yath::Plugin::* modules in order to bring in command-line options they may provide. This flag will disable that. This is useful if you have a naughty plugin that it loading other modules when it should not.


=item --plugins PLUGIN

=item --plugins +App::Yath::Plugin::PLUGIN

=item --plugins PLUGIN=arg1,arg2,...

=item --plugin PLUGIN

=item --plugin +App::Yath::Plugin::PLUGIN

=item --plugin PLUGIN=arg1,arg2,...

=item -pPLUGIN

=item --no-plugins

Load a yath plugin.

Can be specified multiple times


=back

=head2 COMMAND OPTIONS

=head3 Git Options

=over 4

=item --git-change-base master

=item --git-change-base HEAD^

=item --git-change-base df22abe4

=item --no-git-change-base

Find files changed by all commits in the current branch from most recent stopping when a commit is found that is also present in the history of the branch/commit specified as the change base.


=back

=head3 Help and Debugging

=over 4

=item --dummy

=item -d

=item --no-dummy

Dummy run, do not actually execute anything

Can also be set with the following environment variables: C<T2_HARNESS_DUMMY>


=item --help

=item -h

=item --no-help

exit after showing help information


=item --keep-dirs

=item --keep_dir

=item -k

=item --no-keep-dirs

Do not delete directories when done. This is useful if you want to inspect the directories used for various commands.


=back

=head3 YathUI Options

=over 4

=item --yathui-api-key ARG

=item --yathui-api-key=ARG

=item --no-yathui-api-key

Yath-UI API key. This is not necessary if your Yath-UI instance is set to single-user


=item --yathui-grace

=item --no-yathui-grace

If yath cannot connect to yath-ui it normally throws an error, use this to make it fail gracefully. You get a warning, but things keep going.


=item --yathui-long-duration 10

=item --no-yathui-long-duration

Minimum duration length (seconds) before a test goes from MEDIUM to LONG


=item --yathui-medium-duration 5

=item --no-yathui-medium-duration

Minimum duration length (seconds) before a test goes from SHORT to MEDIUM


=item --yathui-mode summary

=item --yathui-mode qvf

=item --yathui-mode qvfd

=item --yathui-mode complete

=item --no-yathui-mode

Set the upload mode (default 'qvfd')


=item --yathui-project ARG

=item --yathui-project=ARG

=item --no-yathui-project

The Yath-UI project for your test results


=item --yathui-retry

=item --no-yathui-retry

How many times to try an operation before giving up

Can be specified multiple times


=item --yathui-url http://my-yath-ui.com/...

=item --uri http://my-yath-ui.com/...

=item --no-yathui-url

Yath-UI url


=back

=head3 spawn options

=over 4

=item --copy-env HOME

=item --copy-env SHELL

=item --copy-env /PERL_.*/i

=item -e HOME

=item -e SHELL

=item -e /PERL_.*/i

=item --no-copy-env

Specify environment variables to pass along with their current values, can also use a regex

Can be specified multiple times


=item --env-var VAR=VAL

=item -EVAR=VAL

=item -E VAR=VAL

=item --no-env-var

Set environment variables for the spawn

Can be specified multiple times


=item --stage foo

=item -s foo

=item --no-stage

Specify the stage to be used for launching the script


=back

=head1 SOURCE

The source code repository for Test2-Harness can be found at
F<http://github.com/Test-More/Test2-Harness/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2020 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut

