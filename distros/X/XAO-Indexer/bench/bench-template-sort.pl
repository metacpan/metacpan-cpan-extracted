#!/usr/bin/env perl
use warnings;
use strict;
use blib;
use XAO::Objects;
use XAO::Utils;
use XAO::IndexerSupport;
use Benchmark;
use Getopt::Long;

my @saved_argv=@ARGV;

my $full_count=500000;
my $part_count=2000;
my $block_count=500;
my $run_count=20;
my $no_sysinfo;
my $with_perl;
GetOptions(
    'debug'             => sub { XAO::Utils::set_debug(1) },
    'full-count=i'      => \$full_count,
    'part-count=i'      => \$part_count,
    'run-count=i'       => \$run_count,
    'block-count=i'     => \$block_count,
    'no-system-info'    => \$no_sysinfo,
    'with-perl'         => \$with_perl,
);
if(@ARGV<1 || $ARGV[0] ne 'yes') {
    print <<EOT;
Usage: $0 \\
    [--debug] \\
    [--full-count $full_count] \\
    [--part-count $part_count] \\
    [--block-count $block_count] \\
    [--run-count $run_count] \\
    [--no-system-info] \\
    [--with-perl] \\
    yes

Benchmarks XAO::IndexerSupport merging sort using given counts or
defaults.

EOT
    exit 1;
}

srand(12345);

if(!$no_sysinfo) {
    dprint "Printing system info";
    print "============= /proc/cpuinfo\n";
    system '/bin/cat /proc/cpuinfo';
    print "============= uname -a\n";
    system '/bin/uname -a';
    print "============= args\n";
    print "$0 ",join(' ',@saved_argv),"\n";
    print "full-count $full_count\n";
    print "part-count $part_count\n";
    print "block-count $block_count\n";
    print "run-count $run_count\n";
    print "============= date\n";
    print scalar(localtime),"\n";
    print "============= benchmark\n";
}

##
# Partial subset is always a subset of the full set, it is guaranteed.
#
dprint "Building full dataset ($full_count)";
my @full_data=(0..$full_count-1);
for(my $i=0; $i<$full_count; ++$i) {
    my $n=int(rand($full_count));
    next if $n==$i;
    ($full_data[$i],$full_data[$n])=($full_data[$n],$full_data[$i]);
}
if($full_count<50) {
    dprint "FULL: ",join(',',@full_data);
}
dprint "Building partial dataset ($part_count)";
my @blocks;
for(my $i=0; $i<$block_count; ++$i) {
    my %part_hash;
    my @part_data;
    while(scalar(@part_data) < $part_count) {
        my $n=$full_data[int(rand($full_count))];
        next if $part_hash{$n};
        $part_hash{$n}=1;
        push(@part_data,$n);
    }
    push(@blocks,\@part_data);
}

dprint "Benchmarking sorting";
timethese($run_count, {
    t1_null         => \&sort_null,
    t3_i_null       => \&sort_i_hollow,
    t3_is_direct    => \&sort_is_direct,
    t3_is_normal    => \&sort_is_normal,
    t3_is_perl      => \&sort_is_perl,
    $with_perl ? (
        t2_perl1        => \&sort_perl1,
        t2_perl2        => \&sort_perl2,
    ) : ( ),
});

exit 0;

###############################################################################

sub sort_null {
    [ 1 ];
}

###############################################################################

sub sort_perl1 {
    my $sorted_ref; # to fool it into thinking we use results
    for(my $i=0; $i<$block_count; ++$i) {
        my %t;
        my $pd=$blocks[$i];
        @t{@$pd}=((undef) x scalar(@$pd));
        my @sorted=map { exists($t{$_}) ? ($_) : () } @full_data;
        $sorted_ref=\@sorted;
    }
}

###############################################################################

sub sort_perl2 {
    my %t;
    @t{@full_data}=(0..$#full_data);
    my $sorted_ref;
    for(my $i=0; $i<$block_count; ++$i) {
        my @sorted=sort { $t{$a} <=> $t{$b} } @{$blocks[$i]};
        $sorted_ref=\@sorted;
    }
}

###############################################################################

sub sort_i_hollow {
    my $full=pack('L*',@full_data);
    my $sorted_ref;
    for(my $i=0; $i<$block_count; ++$i) {
        my $part=pack('L*',@{$blocks[$i]});
        my @sorted=unpack('L*',$part);
        $sorted_ref=\@sorted;
    }
}

###############################################################################

sub sort_is_direct {
    my $full=pack('L*',@full_data);
    XAO::IndexerSupport::template_sort_prepare_do($full);
    my $sorted_ref;
    for(my $i=0; $i<$block_count; ++$i) {
        my $part=pack('L*',@{$blocks[$i]});
        XAO::IndexerSupport::template_sort_do($part);
        my @sorted=unpack('L*',$part);
        $sorted_ref=\@sorted;
    }
}

###############################################################################

sub sort_is_normal {
    XAO::IndexerSupport::template_sort_prepare(\@full_data);
    my $sorted_ref;
    for(my $i=0; $i<$block_count; ++$i) {
        $sorted_ref=XAO::IndexerSupport::template_sort($blocks[$i]);
    }
}

###############################################################################

sub sort_is_perl {
    XAO::IndexerSupport::template_sort_prepare(\@full_data);
    my $sorted_ref;
    for(my $i=0; $i<$block_count; ++$i) {
        $sorted_ref=[
            sort {
                XAO::IndexerSupport::template_sort_compare($a,$b)
            } @{$blocks[$i]}
        ];
    }
}
