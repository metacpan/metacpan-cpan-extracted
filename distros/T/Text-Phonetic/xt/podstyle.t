use strict;
use warnings;
use Test::More;

eval "use Pod::Simple::SimpleTree";
plan skip_all => 'Pod::Simple::SimpleTree required' if $@;
eval "use Test::Pod";
plan skip_all => 'Test::Pod required' if $@;
plan skip_all => 'set TEST_AUTHOR to enable this test' unless $ENV{TEST_AUTHOR};

my @files;
foreach (all_pod_files()) {
    next if /Schema\//;
    next if /\.pl$/;
    push @files,$_;
}

my @required_heads=qw(NAME SYNOPSIS DESCRIPTION METHODS AUTHOR LICENSE COPYRIGHT);

plan tests => scalar @files * scalar @required_heads;

foreach my $file (@files) {

    my $parser=Pod::Simple::SimpleTree->new;
    $parser->accept_targets('*');
    my $root=$parser->parse_file($file)->root;
    shift(@$root);shift(@$root);

    my @heads;
    my %heads;
    foreach my $node (@$root) {
        next unless $node->[0] eq 'head1';
        push(@heads,$node->[2]);
        $heads{$node->[2]}=1;
    }
   
    foreach my $heading (@required_heads) {
        ok($heads{$heading},"$file has $heading");
    }

}



