#!/usr/bin/env perl

=head1 DESCRIPTION

  this is sample worker.

=head1 SYNOPSIS

  % agent.pl --log error.log

=cut

use strict;
use warnings;
use utf8;
use Getopt::Long qw/:config posix_default no_ignore_case bundling auto_help/;
use Pod::Usage qw/pod2usage/;
use IO::Handle;

# get options
GetOptions(
    \my %opt, qw/
      log=s
      all
      /
) or pod2usage(1);

my @required_options = qw/log/;
pod2usage(2) if grep { !exists $opt{$_} } @required_options;

# open log file
open my $fh, '>', $opt{log} or die "";
$fh->autoflush(1);

# start app
my $count = 0;
while (1) {
    sleep 1;
    $count++;

    $fh->print("number $count\n");
    last if $count == 3;
}
