#!/usr/bin/env perl -w

( my $exe = $0 ) =~ s{[^/\\]+$}{check.pl};
do $exe;

