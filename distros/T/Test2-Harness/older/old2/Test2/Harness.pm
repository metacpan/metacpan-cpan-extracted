package Test2::Harness;
use strict;
use warnings;

use Test2::Harness::Run;
use Test2::Harness::Worker;

use Test2::Harness::HashBase qw/-_runs -config/;

use File::Temp qw/tempfile/;
use Storable qw/store_fd retrieve/;

sub init {
    my $self = shift;

    $self->{+_RUNS}  ||= [];
    $self->{+CONFIG} ||= Test2::Harness::Config->new;
}

sub runs { @{$_[0]->{+_RUNS}} }

sub run {
    my $self = shift;
    my $class = ref($self);

    my ($run_h, $run_file)   = tempfile("T2HARNESS-XXXXXX", SUFFIX => '.run');
    my ($conf_h, $conf_file) = tempfile("T2HARNESS-XXXXXX", SUFFIX => '.conf');

    store_fd($self->{+CONFIG}, $conf_h) or die "Could not store config file";
    close($conf_h);

    print $run_h "This will be replaced\n";
    close($run_h);

    my $exit = system(
        $^X,
        "-MTest2::Harness::Worker=$conf_file,$run_file",
        '-e' => Test2::Harness::Worker->runtime_code(),
    );

    my $run = retrieve($run_file);
    $run->set_exit($exit);
    unlink($run_file);

    push @{$self->{+_RUNS}} => $run;

    return $run;
}

1;
