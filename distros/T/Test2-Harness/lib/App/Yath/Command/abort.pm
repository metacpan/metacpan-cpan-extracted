package App::Yath::Command::abort;
use strict;
use warnings;

our $VERSION = '2.000005';

use App::Yath::Client;

use parent 'App::Yath::Command';
use Test2::Harness::Util::HashBase;

sub group { 'daemon' }

sub summary { "Remove any pending tests, will not stop currently running tests, leaves the runner active" }
sub cli_args { "" }

sub description {
    return <<"    EOT";
This command will kill the active yath runner and any running or pending tests.
    EOT
}

use Getopt::Yath;
include_options(
    'App::Yath::Options::IPC',
    'App::Yath::Options::Yath',
);

sub run {
    my $self = shift;

    my $settings = $self->settings;
    my $client = App::Yath::Client->new(settings => $settings);

    $client->abort();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Command::abort - Remove any pending tests, will not stop currently running tests, leaves the runner active

=head1 DESCRIPTION

This command will kill the active yath runner and any running or pending tests.


=head1 USAGE

    $ yath [YATH OPTIONS] abort [COMMAND OPTIONS]

=head2 OPTIONS

=head3 Harness Options

=over 4

=item -d

=item --dummy

=item --no-dummy

Dummy run, do not actually execute anything

Can also be set with the following environment variables: C<T2_HARNESS_DUMMY>

The following environment variables will be cleared after arguments are processed: C<T2_HARNESS_DUMMY>


=item --procname-prefix ARG

=item --procname-prefix=ARG

=item --no-procname-prefix

Add a prefix to all proc names (as seen by ps).

The following environment variables will be set after arguments are processed: C<T2_HARNESS_PROC_PREFIX>


=back

=head3 IPC Options

=over 4

=item --ipc-address ARG

=item --ipc-address=ARG

=item --no-ipc-address

IPC address to use (usually auto-generated or discovered)


=item --ipc-allow-multiple

=item --no-ipc-allow-multiple

Normally yath will prevent you from starting multiple persistent runners in the same project, this option will allow you to start more than one.


=item --ipc-dir ARG

=item --ipc-dir=ARG

=item --no-ipc-dir

Directory for ipc files

Can also be set with the following environment variables: C<T2_HARNESS_IPC_DIR>, C<YATH_IPC_DIR>


=item --ipc-dir-order ARG

=item --ipc-dir-order=ARG

=item --ipc-dir-order '["json","list"]'

=item --ipc-dir-order='["json","list"]'

=item --ipc-dir-order :{ ARG1 ARG2 ... }:

=item --ipc-dir-order=:{ ARG1 ARG2 ... }:

=item --no-ipc-dir-order

When finding ipc-dir automatically, search in this order, default: ['base', 'temp']

Note: Can be specified multiple times


=item --ipc-file ARG

=item --ipc-file=ARG

=item --no-ipc-file

IPC file used to locate instances (usually auto-generated or discovered)


=item --ipc-peer-pid ARG

=item --ipc-peer-pid=ARG

=item --no-ipc-peer-pid

Optionally a peer PID may be provided


=item --ipc-port ARG

=item --ipc-port=ARG

=item --no-ipc-port

Some IPC protocols require a port, otherwise this should be left empty


=item --ipc-prefix ARG

=item --ipc-prefix=ARG

=item --no-ipc-prefix

Prefix for ipc files


=item --ipc-protocol IPSocket

=item --ipc-protocol AtomicPipe

=item --ipc-protocol UnixSocket

=item --ipc-protocol +Test2::Harness::IPC::Protocol::AtomicPipe

=item --no-ipc-protocol

Specify what IPC Protocol to use. Use the "+" prefix to specify a fully qualified namespace, otherwise Test2::Harness::IPC::Protocol::XXX namespace is assumed.


=back

=head3 Yath Options

=over 4

=item --base-dir ARG

=item --base-dir=ARG

=item --no-base-dir

Root directory for the project being tested (usually where .yath.rc lives)


=item -D

=item -Dlib

=item -Dlib

=item -D=lib

=item -D"lib/*"

=item --dev-lib

=item --dev-lib=lib

=item --dev-lib="lib/*"

=item --no-dev-lib

This is what you use if you are developing yath or yath plugins to make sure the yath script finds the local code instead of the installed versions of the same code. You can provide an argument (-Dfoo) to provide a custom path, or you can just use -D without and arg to add lib, blib/lib and blib/arch.

Note: This option can cause yath to use exec() to reload itself with the correct libraries in place. Each occurence of this argument can cause an additional exec() call. Use --dev-libs-verbose BEFORE any -D calls to see the exec() calls.

Note: Can be specified multiple times


=item --dev-libs-verbose

=item --no-dev-libs-verbose

Be verbose and announce that yath will re-exec in order to have the correct includes (normally yath will just call exec() quietly)


=item -h

=item -h=Group

=item --help

=item --help=Group

=item --no-help

exit after showing help information


=item -p key=val

=item -p=key=val

=item -pkey=value

=item -p '{"json":"hash"}'

=item -p='{"json":"hash"}'

=item -p:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item -p :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item -p=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --plugin key=val

=item --plugin=key=val

=item --plugins key=val

=item --plugins=key=val

=item --plugin '{"json":"hash"}'

=item --plugin='{"json":"hash"}'

=item --plugins '{"json":"hash"}'

=item --plugins='{"json":"hash"}'

=item --plugin :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --plugin=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --plugins :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --plugins=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --no-plugins

Load a yath plugin.

Note: Can be specified multiple times


=item --project ARG

=item --project=ARG

=item --project-name ARG

=item --project-name=ARG

=item --no-project

This lets you provide a label for your current project/codebase. This is best used in a .yath.rc file.


=item --scan-options key=val

=item --scan-options=key=val

=item --scan-options '{"json":"hash"}'

=item --scan-options='{"json":"hash"}'

=item --scan-options(?^:^--(no-)?(?^:scan-(.+))$)

=item --scan-options :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --scan-options=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --no-scan-options

=item /^--(no-)?scan-(.+)$/

Yath will normally scan plugins for options. Some commands scan other libraries (finders, resources, renderers, etc) for options. You can use this to disable all scanning, or selectively disable/enable some scanning.

Note: This is parsed early in the argument processing sequence, before options that may be earlier in your argument list.

Note: Can be specified multiple times


=item --show-opts

=item --show-opts=group

=item --no-show-opts

Exit after showing what yath thinks your options mean


=item --user ARG

=item --user=ARG

=item --no-user

Username to associate with logs, database entries, and yath servers.

Can also be set with the following environment variables: C<YATH_USER>, C<USER>


=item -V

=item --version

=item --no-version

Exit after showing a helpful usage message


=back


=head1 SOURCE

The source code repository for Test2-Harness can be found at
L<http://github.com/Test-More/Test2-Harness/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
