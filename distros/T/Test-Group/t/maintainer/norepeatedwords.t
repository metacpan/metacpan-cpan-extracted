#!perl -w

use strict;

=head1 NAME

norepeatedwords.t - Checks that there are no repeated words in the
source code.

=cut

use Test::More;
unless (eval <<"USE") {
use Test::NoBreakpoints qw(all_perl_files);
1;
USE
    plan skip_all => "Test::NoBreakpoints required";
    warn $@ if $ENV{DEBUG};
    exit;
}

plan 'no_plan';

foreach my $file (all_perl_files(qw(Build.PL Build lib t))) {
    local *FILE;
    open(FILE, $file) or die "Cannot open $file for reading: $!\n";
    local $/;
    local $_ = <FILE>;

    # Some word repeats are ok
    s/API that that class/API that-that class/;
    s/\bwoo woo\b/woo-woo/g;
    
    my @fail;
    while (/\s((\w{2,})\s{1,5}\2)[\s,.]/ig) {
        push @fail, "repeated words [$1]";
    }
    ok(! @fail, "no repeated words found in $file");
    foreach my $fail (@fail) {
        diag $fail;
    }
}
