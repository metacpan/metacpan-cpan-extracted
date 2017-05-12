package Ukigumo::Agent::Cleaner;
use strict;
use warnings;
use utf8;
use parent "Exporter";
use File::Path qw/rmtree/;

our @EXPORT_OK = qw/cleanup_old_branch_dir/;

sub ONE_DAY { 60 * 60 * 24 }

sub cleanup_old_branch_dir {
    my ($parent_dir, $cleanup_cycle) = @_;

    return if $cleanup_cycle <= 0;

    my $now = time;
    for my $branches_dir (glob "$parent_dir/*") {
        my $last_modified = (stat $branches_dir)[9];
        if ($now - $last_modified > $cleanup_cycle * ONE_DAY()) {
            rmtree($branches_dir);
        }
    }
}

1;

