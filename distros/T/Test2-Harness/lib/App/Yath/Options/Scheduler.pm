package App::Yath::Options::Scheduler;
use strict;
use warnings;

use Test2::Harness::Util qw/fqmod/;

our $VERSION = '2.000005';

use Getopt::Yath;
include_options(
    'App::Yath::Options::Tests',
);

option_group {group => 'scheduler', category => 'Scheduler Options'} => sub {
    option class => (
        name    => 'scheduler',
        field   => 'class',
        type    => 'Scalar',
        default => 'Test2::Harness::Scheduler',

        mod_adds_options => 1,
        long_examples    => [' MyScheduler', ' +Test2::Harness::MyScheduler'],
        description      => 'Specify what Scheduler subclass to use. Use the "+" prefix to specify a fully qualified namespace, otherwise Test2::Harness::Scheduler::XXX namespace is assumed.',

        normalize => sub { fqmod($_[0], 'Test2::Harness::Scheduler') },
    );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Options::Scheduler - Scheduler options for Yath.

=head1 DESCRIPTION

This is where command line options for the runner are defined.

=head1 PROVIDED OPTIONS

=head2 Scheduler Options

=over 4

=item --scheduler MyScheduler

=item --scheduler +Test2::Harness::MyScheduler

=item --no-scheduler

Specify what Scheduler subclass to use. Use the "+" prefix to specify a fully qualified namespace, otherwise Test2::Harness::Scheduler::XXX namespace is assumed.


=back

=head2 Test Options

=over 4

=item --allow-retry

=item --no-allow-retry

Toggle retry capabilities on and off (default: on)


=item -b

=item --blib

=item --no-blib

(Default: include if it exists) Include 'blib/lib' and 'blib/arch' in your module path (These will come after paths you specify with -D or -I)


=item --cover

=item --cover=-silent,1,+ignore,^t/,+ignore,^t2/,+ignore,^xt,+ignore,^test.pl

=item --no-cover

Use Devel::Cover to calculate test coverage. This disables forking. If no args are specified the following are used: -silent,1,+ignore,^t/,+ignore,^t2/,+ignore,^xt,+ignore,^test.pl

Can also be set with the following environment variables: C<T2_DEVEL_COVER>

The following environment variables will be set after arguments are processed: C<T2_DEVEL_COVER>


=item -E key=val

=item -E=key=val

=item -Ekey=value

=item -E '{"json":"hash"}'

=item -E='{"json":"hash"}'

=item -E:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item -E :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item -E=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --env-var key=val

=item --env-var=key=val

=item --env-vars key=val

=item --env-vars=key=val

=item --env-var '{"json":"hash"}'

=item --env-var='{"json":"hash"}'

=item --env-vars '{"json":"hash"}'

=item --env-vars='{"json":"hash"}'

=item --env-var :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --env-var=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --env-vars :{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --env-vars=:{ KEY1 VAL KEY2 :{ VAL1 VAL2 ... }: ... }:

=item --no-env-vars

Set environment variables

Note: Can be specified multiple times


=item --et SECONDS

=item --event-timeout SECONDS

=item --no-event-timeout

Kill test if no output is received within timeout period. (Default: 60 seconds). Add the "# HARNESS-NO-TIMEOUT" comment to the top of a test file to disable timeouts on a per-test basis. This prevents a hung test from running forever.


=item --event-uuids

=item --no-event-uuids

Use Test2::Plugin::UUID inside tests (default: on)


=item -I ARG

=item -I=ARG

=item -I '*.*'

=item -I='*.*'

=item -I '["json","list"]'

=item -I='["json","list"]'

=item -I :{ ARG1 ARG2 ... }:

=item -I=:{ ARG1 ARG2 ... }:

=item --include ARG

=item --include=ARG

=item --include '*.*'

=item --include='*.*'

=item --include '["json","list"]'

=item --include='["json","list"]'

=item --include :{ ARG1 ARG2 ... }:

=item --include=:{ ARG1 ARG2 ... }:

=item --no-include

Add a directory to your include paths

Note: Can be specified multiple times


=item --input ARG

=item --input=ARG

=item --no-input

Input string to be used as standard input for ALL tests. See also: --input-file


=item --input-file ARG

=item --input-file=ARG

=item --no-input-file

Use the specified file as standard input to ALL tests


=item -l

=item --lib

=item --no-lib

(Default: include if it exists) Include 'lib' in your module path (These will come after paths you specify with -D or -I)


=item -m ARG

=item -m=ARG

=item -m '["json","list"]'

=item -m='["json","list"]'

=item -m :{ ARG1 ARG2 ... }:

=item -m=:{ ARG1 ARG2 ... }:

=item --load ARG

=item --load=ARG

=item --load-module ARG

=item --load-module=ARG

=item --load '["json","list"]'

=item --load='["json","list"]'

=item --load :{ ARG1 ARG2 ... }:

=item --load=:{ ARG1 ARG2 ... }:

=item --load-module '["json","list"]'

=item --load-module='["json","list"]'

=item --load-module :{ ARG1 ARG2 ... }:

=item --load-module=:{ ARG1 ARG2 ... }:

=item --no-load

Load a module in each test (after fork). The "import" method is not called.

Note: Can be specified multiple times


=item -M Module

=item -M Module=import_arg1,arg2,...

=item -M '{"Data::Dumper":["Dumper"]}'

=item --loadim Module

=item --load-import Module

=item --loadim Module=import_arg1,arg2,...

=item --loadim '{"Data::Dumper":["Dumper"]}'

=item --load-import Module=import_arg1,arg2,...

=item --load-import '{"Data::Dumper":["Dumper"]}'

=item --no-load-import

Load a module in each test (after fork). Import is called.

Note: Can be specified multiple times


=item --mem-usage

=item --no-mem-usage

Use Test2::Plugin::MemUsage inside tests (default: on)


=item --pet SECONDS

=item --post-exit-timeout SECONDS

=item --no-post-exit-timeout

Stop waiting post-exit after the timeout period. (Default: 15 seconds) Some tests fork and allow the parent to exit before writing all their output. If Test2::Harness detects an incomplete plan after the test exits it will monitor for more events until the timeout period. Add the "# HARNESS-NO-TIMEOUT" comment to the top of a test file to disable timeouts on a per-test basis.


=item -rARG

=item -r ARG

=item -r=ARG

=item --retry ARG

=item --retry=ARG

=item --no-retry

Run any jobs that failed a second time. NOTE: --retry=1 means failing tests will be attempted twice!


=item --retry-iso

=item --retry-isolated

=item --no-retry-isolated

If true then any job retries will be done in isolation (as though -j1 was set)


=item --stream

=item --use-stream

=item --no-stream

=item --TAP

The TAP format is lossy and clunky. Test2::Harness normally uses a newer streaming format to receive test results. There are old/legacy tests where this causes problems, in which case setting --TAP or --no-stream can help.


=item -S ARG

=item -S=ARG

=item -S '["json","list"]'

=item -S='["json","list"]'

=item -S :{ ARG1 ARG2 ... }:

=item -S=:{ ARG1 ARG2 ... }:

=item --switch ARG

=item --switch=ARG

=item --switches ARG

=item --switches=ARG

=item --switch '["json","list"]'

=item --switch='["json","list"]'

=item --switches '["json","list"]'

=item --switches='["json","list"]'

=item --switch :{ ARG1 ARG2 ... }:

=item --switch=:{ ARG1 ARG2 ... }:

=item --switches :{ ARG1 ARG2 ... }:

=item --switches=:{ ARG1 ARG2 ... }:

=item --no-switches

Pass the specified switch to perl for each test. This is not compatible with preload.

Note: Can be specified multiple times


=item --test-arg ARG

=item --test-arg=ARG

=item --test-args ARG

=item --test-args=ARG

=item --test-arg '["json","list"]'

=item --test-arg='["json","list"]'

=item --test-args '["json","list"]'

=item --test-args='["json","list"]'

=item --test-arg :{ ARG1 ARG2 ... }:

=item --test-arg=:{ ARG1 ARG2 ... }:

=item --test-args :{ ARG1 ARG2 ... }:

=item --test-args=:{ ARG1 ARG2 ... }:

=item --no-test-args

Arguments to pass in as @ARGV for all tests that are run. These can be provided easier using the '::' argument separator.

Note: Can be specified multiple times


=item --tlib

=item --no-tlib

(Default: off) Include 't/lib' in your module path (These will come after paths you specify with -D or -I)


=item --unsafe-inc

=item --no-unsafe-inc

perl is removing '.' from @INC as a security concern. This option keeps things from breaking for now.

Can also be set with the following environment variables: C<PERL_USE_UNSAFE_INC>

The following environment variables will be set after arguments are processed: C<PERL_USE_UNSAFE_INC>


=item --fork

=item --use-fork

=item --no-use-fork

(default: on, except on windows) Normally tests are run by forking, which allows for features like preloading. This will turn off the behavior globally (which is not compatible with preloading). This is slower, it is better to tag misbehaving tests with the '# HARNESS-NO-PRELOAD' comment in their header to disable forking only for those tests.

Can also be set with the following environment variables: C<!T2_NO_FORK>, C<T2_HARNESS_FORK>, C<!T2_HARNESS_NO_FORK>, C<YATH_FORK>, C<!YATH_NO_FORK>


=item --timeout

=item --use-timeout

=item --no-use-timeout

(default: on) Enable/disable timeouts


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
