#! /usr/bin/env perl

use strict;
use warnings;
use 5.012;
use autodie;

use Pod::Help qw(-h --help);
use Getopt::Std;
use Text::Cadenceparser;


my %opts;

# Extract the power and area file options if they are passed.
getopt('pa', \%opts);

Pod::Help->help() if (!defined $opts{a} && !defined $opts{p});

# Set defaul values for the mode based on what files are specced
my $mode;
$mode = 'area' if (defined $opts{a});
$mode = 'active' if (defined $opts{p});

# And override in case they are apssed as argument
$mode      = $ARGV[0] || $mode;
my $threshold = $ARGV[1] || '';


my $parser = Text::Cadenceparser->new(
    'key'       => $mode,
    'threshold' => $threshold,
    'area_rpt'  => $opts{a},
    'power_rpt' => $opts{p}
);
$parser->report();

exit;

# ABSTRACT: Merge and sort the area and power reports of Cadence synthesis runs
# PODNAME: synth_merge.pl

__END__

=pod

=head1 NAME

synth_merge.pl - Merge and sort the area and power reports of Cadence synthesis runs

=head1 VERSION

version 1.12

=head1 DESCRIPTION

This script merges area and power reports of tests of Cadence synthesis runs.
It enables sorting the design hierarchy according to their
percentage-wise contribution of the total area, active power, or leakage.

=head1 SYNOPSYS

Usage:
synth_merge.pl -a <area_file> -p <power_file> <mode> <threshold>

It is allowed to only pass either an area file or a power file. If
both files are passed, the results of both files are merged.

Also, it is not required to fill in C<mode> or C<threshold>.
If only an area file is passed, the C<mode> defaults to 'area'.
If only a power file is passed, C<mode> defaults to 'active'.
C<threshold> defaults to 1. This means that every unit that contributes
for more than one percent will be displayed. The other units will be
folded together and will be reported as a group at the end of the log.

Some more details on the parameters:

=over

=item area_rpt : Encounter RTL compiler file containing the area log

=item power_rpt: Encounter RTL compiler file containing the power log

=item mode: determines the sorting mode and can be

=over

=item area

=item active

=item leakage

=back

=item threshold: determined from what % of the selected mode the design hierarchy will be reported

=back

=head1 AUTHOR

Lieven Hollevoet <hollie@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Lieven Hollevoet.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
