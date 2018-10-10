#!/usr/bin/env perl -T

use strict;
use warnings;

use Test::Pod;

my @pod_dirs = qw(lib t);

all_pod_files_ok(all_pod_files(@pod_dirs));
__END__

=head1 NAME

t/999-pod.t

=head1 DESCRIPTION

Check all available PM files for valid POD.

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

