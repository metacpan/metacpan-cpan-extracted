use strict;
use inc::Module::Install;

=head1 SWITCHES

To skip testing for the presence
of a C<exim4> command, use the C<--skip-exim4>
or the C<--exim4=/opt/exim4/exim4> command line
switch.

Alternatively, set C<$ENV{SKIP_EXIM4}> to
a true value.

=cut

use Getopt::Long;
GetOptions(
    'exim4:s' => \my $exim4,
    'skip-exim4' => \my $skip_exim4,
);
$exim4 ||= $ENV{SKIP_EXIM4};

# This means that Makefile.PL must be run by
# somebody who has exim4 in the path. This is likely root.

if (not ($exim4 or $skip_exim4)) {
    requires_external_bin( 'exim4' );
};

name 'Test-Exim4-Routing';
all_from 'lib/Test/Exim4/Routing.pm';

requires 'parent' => 0.218;
requires 'Test::Builder'  => 0; # This is what we are
requires 'Test::More'  => 0; # for testing, duh

WriteAll;
