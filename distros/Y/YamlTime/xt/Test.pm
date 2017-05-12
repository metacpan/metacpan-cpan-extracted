package Test;
use strict;
use base 'Exporter';
use Cwd qw'cwd abs_path';
use File::Path qw(mkpath rmtree);

our @EXPORT = qw(run cmd abs_path mkpath rmtree $HOME $YEAR);

my @time = localtime;
our $YEAR = $time[5] + 1900;
our $HOME = abs_path '.';
$ENV{PATH} = abs_path('bin') . ":$ENV{PATH}";

sub import {
    strict->import;
    warnings->import;
    goto &Exporter::import;
}

sub run {
    my $cmd = shift;
    warn ">> $cmd\n";
    system($cmd) == 0 or @_ or die "Error: '$cmd' failed\n";
}

1;
