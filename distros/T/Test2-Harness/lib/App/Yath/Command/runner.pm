package App::Yath::Command::runner;
use strict;
use warnings;

our $VERSION = '1.000038';

use Config qw/%Config/;
use File::Spec;
use goto::file();
use Test2::Harness::IPC();

use Carp qw/confess/;
use Scalar::Util qw/openhandle/;
use List::Util qw/first/;
use File::Path qw/remove_tree/;

use Scope::Guard;

use Test2::Util qw/clone_io/;

use Long::Jump qw/setjump longjump/;

use Test2::Harness::Util qw/mod2file write_file_atomic open_file clean_path process_includes/;

use Test2::Harness::Util::IPC qw/swap_io/;

use Test2::Harness::Runner::Preloader();

my @SIGNALS = grep { $_ ne 'ZERO' } split /\s+/, $Config{sig_name};

# If FindBin is installed, go ahead and load it. We do not care much about
# success vs failure here.
BEGIN {
    local $@;
    eval { require FindBin; FindBin->import };
}

use parent 'App::Yath::Command';
use Test2::Harness::Util::HashBase;

sub internal_only { 1 }
sub summary       { "For internal use only" }
sub name          { 'runner' }

sub init { confess(ref($_[0]) . " is not intended to be instantiated") }
sub run  { confess(ref($_[0]) . " does not implement run()") }

sub generate_run_sub {
    my $class = shift;
    my ($symbol, $argv, $spawn_settings) = @_;
    my ($dir, %args) = @$argv;

    $0 = $ENV{NESTED_YATH} ? 'yath-nested-runner' : 'yath-runner';

    my $settings = Test2::Harness::Settings->new(File::Spec->catfile($dir, 'settings.json'));

    my $cleanup = $class->cleanup($settings, \%args, $dir);

    my $runner_pid = $$;
    my $jump = setjump "Test-Runner" => sub {
        local $.;

        my %orig_sig = %SIG;
        my $guard = Scope::Guard->new(sub {
            my %seen;
            for my $sig (@SIGNALS) {
                next if $seen{$sig}++;
                if (exists $orig_sig{$sig}) {
                    $SIG{$sig} = $orig_sig{$sig};
                }
                else {
                    delete $SIG{$sig};
                }
            }
        });

        my $runner = $settings->build(
            runner => 'Test2::Harness::Runner',

            %args,

            dir      => $dir,
            settings => $settings,

            fork_job_callback       => sub { $class->launch_via_fork(@_) },
            fork_spawn_callback     => sub { $class->launch_spawn(@_) },
            respawn_runner_callback => sub { return unless $$ == $runner_pid; longjump "Test-Runner" => 'respawn' },
        );

        my $exit = $runner->process();

        if ($$ == $runner_pid) {
            $_->cleanup() for @{$runner->state->resources};
        }

        my $complete = File::Spec->catfile($dir, 'complete');
        write_file_atomic($complete, '1');

        exit($exit // 1);
    };

    die "Test runner completed, but failed to exit" unless $jump;

    my ($action, $job, $stage) = @$jump;

    if($action eq 'respawn') {
        print "$$ Respawning the runner...\n";
        $cleanup->dismiss(1);
        exec($^X, $settings->harness->script, @{$spawn_settings->harness->orig_argv});
        warn "exec failed!";
        exit 1;
    }

    die "Invalid action: $action" if $action ne 'run_test';

    if (my $chdir = $job->ch_dir) {
        chdir($chdir) or die "Could not chdir: $!";
    }
    goto::file->import($job->run_file);
    $class->cleanup_process($job, $stage);
    DB::enable_profile() if $settings->runner->nytprof;
}

sub cleanup {
    my $class = shift;
    my ($settings, $args, $dir) = @_;

    my $pfile = $args->{persist} or return;

    my $pid = $$;
    return Scope::Guard->new(sub {
        return unless $pid == $$;

        unlink($pfile);

        remove_tree($dir, {safe => 1, keep_root => 0}) unless $settings->debug->keep_dirs;
    });
}

sub get_stage {
    my $class = shift;
    my ($runner) = @_;

    return unless $runner->can('stage');

    my $stage_name = $runner->stage     or return;
    my $preloader  = $runner->preloader or return;
    my $p          = $preloader->staged or return;

    return $p->stage_lookup->{$stage_name};
}

sub launch_spawn {
    my $class = shift;
    my ($runner, $spawn) = @_;

    my $pid = fork() // die $!;
    if ($pid) {
        waitpid($pid, 0);
        return;
    }

    require POSIX;
    POSIX::setsid or die "setsid: $!";

    $pid = fork // die $!;
    exit 0 if $pid;

    eval {
        my ($wh);
        pipe(STDIN, $wh) or die "Could not create pipe: $!";
        $pid = $class->launch_via_fork($runner, $spawn);

        if ($pid) {
            open(my $fh, '>>', $spawn->{task}->{ipcfile}) or die "Could not open pidfile: $!";
            print $fh "$$\n$pid\n" . fileno($wh) . "\n";
            $fh->flush();
            waitpid($pid, 0);
            print $fh "$?\n";
            close($fh);
        }

        exit(0);
    };
    warn "Unknown problem daemonizing: $@";
    exit(1);
}

sub launch_via_fork {
    my $class = shift;
    my ($runner, $job) = @_;

    my $stage = $class->get_stage($runner);

    $stage->do_pre_fork($job) if $stage;

    my $pid = fork();
    die "Failed to fork: $!" unless defined $pid;

    # In parent
    return $pid if $pid;

    # In Child
    my $ok = eval {
        $0 = 'yath-pending-test';
        setpgrp(0, 0) if Test2::Harness::IPC::USE_P_GROUPS();
        $runner->stop();

        $stage->do_post_fork($job) if $stage;

        longjump "Test-Runner" => ('run_test', $job, $stage);

        1;
    };
    my $err = $@;
    eval { warn $err } unless $ok;
    exit(1);
}

sub cleanup_process {
    my $class = shift;
    my ($job, $stage) = @_;

    $class->update_io($job);           # Get the correct filehandles in place early
    $class->set_env($job);             # Set up the necessary env vars
    $class->build_init_state($job);    # Lots of 'misc' stuff.
    $class->do_loads($job);            # Modules that we wanted loaded/imported post fork
    $class->test2_state($job);         # Normalize the Test2 state

    $stage->do_pre_launch($job) if $stage;

    $class->final_state($job); # Important final cleanup
}

sub test2_state {
    my $class = shift;
    my ($job) = @_;

    if ($INC{'Test2/API.pm'}) {
        Test2::API::test2_stop_preload();
        Test2::API::test2_post_preload_reset();
    }

    if ($job->use_stream) {
        $ENV{T2_FORMATTER} = 'Stream';
        require Test2::Formatter::Stream;
        Test2::Formatter::Stream->import(dir => $job->event_dir, job_id => $job->job_id);
    }

    if ($job->event_uuids) {
        require Test2::Plugin::UUID;
        Test2::Plugin::UUID->import();
    }

    if ($job->mem_usage) {
        require Test2::Plugin::MemUsage;
        Test2::Plugin::MemUsage->import();
    }

    if ($job->io_events) {
        require Test2::Plugin::IOEvents;
        Test2::Plugin::IOEvents->import();
    }

    return;
}

sub final_state {
    my $class = shift;
    my ($job) = @_;

    @ARGV = $job->args;

    # toggle -w switch late
    $^W = 1 if $job->use_w_switch;

    # reset the state of empty pattern matches, so that they have the same
    # behavior as running in a clean process.
    # see "The empty pattern //" in perlop.
    # note that this has to be dynamically scoped and can't go to other subs
    "" =~ /^/;

    return;
}

sub do_loads {
    my $class = shift;
    my ($job) = @_;

    local $@;
    my $importer = eval <<'    EOT' or die $@;
package main;
#line 0 "-"
sub { $_[0]->import(@{$_[1]}) }
    EOT

    for my $set ($job->load_import) {
        my ($mod, $args) = @$set;
        my $file = mod2file($mod);
        local $0 = '-';
        require $file;
        $importer->($mod, $args);
    }

    for my $mod ($job->load) {
        my $file = mod2file($mod);
        local $0 = '-';
        require $file;
    }

    return;
}

sub build_init_state {
    my $class = shift;
    my ($job) = @_;

    $0 = $job->rel_file;
    $class->_reset_DATA();
    @ARGV = ();

    srand();    # avoid child processes sharing the same seed value as the parent

    @INC = process_includes(
        list            => [$job->includes],
        include_dot     => $job->unsafe_inc,
        include_current => 1,
        clean           => 1,
    );

    # if FindBin is preloaded, reset it with the new $0
    FindBin::init() if defined &FindBin::init;

    # restore defaults
    Getopt::Long::ConfigDefaults() if defined &Getopt::Long::ConfigDefaults;

    return;
}

sub set_env {
    my $class = shift;
    my ($job) = @_;

    my $env = $job->env_vars;
    {
        no warnings 'uninitialized';
        $ENV{$_} = $env->{$_} for keys %$env;
    }

    $ENV{T2_HARNESS_FORKED}  = 1;
    $ENV{T2_HARNESS_PRELOAD} = 1;

    return;
}

sub update_io {
    my $class = shift;
    my ($job) = @_;

    my $out_fh = open_file($job->out_file, '>');
    my $err_fh = open_file($job->err_file, '>');
    my $in_file = $job->in_file;
    my $in_fh = open_file($in_file,  '<') if $in_file;

    $out_fh->autoflush(1);
    $err_fh->autoflush(1);

    # Keep a copy of the old STDERR for a while so we can still report errors
    my $stderr = clone_io(\*STDERR);

    my $die = sub {
        my @caller = caller;
        my @caller2 = caller(1);
        my $msg = "$_[0] at $caller[1] line $caller[2] ($caller2[1] line $caller2[2]).\n";
        print $stderr $msg;
        print STDERR $msg;
        POSIX::_exit(127);
    };

    swap_io(\*STDIN,  $in_fh,  $die, '<&') if $in_file;
    swap_io(\*STDOUT, $out_fh, $die, '>&');
    swap_io(\*STDERR, $err_fh, $die, '>&');

    return;
}

# Heavily modified from forkprove
sub _reset_DATA {
    my $class = shift;

    for my $set (@{$class->preload_list}) {
        my ($mod, $file, $pos) = @$set;

        my $fh = do {
            no strict 'refs';
            *{$mod . '::DATA'};
        };

        # note that we need to ensure that each forked copy is using a
        # different file handle, or else concurrent processes will interfere
        # with each other

        close $fh if openhandle($fh);

        if (open $fh, '<', $file) {
            seek($fh, $pos, 0);
        }
        else {
            warn "Couldn't reopen DATA for $mod ($file): $!";
        }
    }
}

# Heavily modified from forkprove
sub preload_list {
    my $class = shift;

    my $list = [];

    for my $loaded (keys %INC) {
        next unless $loaded =~ /\.pm$/;

        my $mod = $loaded;
        $mod =~ s{/}{::}g;
        $mod =~ s{\.pm$}{};

        my $fh = do {
            no strict 'refs';
            no warnings 'once';
            *{$mod . '::DATA'};
        };

        next unless openhandle($fh);
        push @$list => [$mod, $INC{$loaded}, tell($fh)];
    }

    return $list;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Command::runner - For internal use only

=head1 DESCRIPTION

No Description

=head1 USAGE

    $ yath [YATH OPTIONS] runner [COMMAND OPTIONS]

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

