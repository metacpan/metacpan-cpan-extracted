use v5.14;
use utf8;
use strict;
use warnings;
use autodie;

binmode(STDOUT, ":utf8");

my $élève = 1; # my $\x{E9}l\x{E8}ve = 1; ## NFC
my $élève = 2; # my $e\x{301}le\x{300}ve = 2; ## NFD
my $élève = 3; # my $\x{E9}le\x{300}ve = 3; ## mixed
my $élève = 4; # my $e\x{301}l\x{E8}ve = 4; ## mixed

printf "%s is %d\n", élève => $élève;
                  # \x{E9}l\x{E8}ve => $\x{E9}l\x{E8}ve;
printf "%s is %d\n", élève => $élève;
                  # e\x{301}le\x{300}ve => $e\x{301}le\x{300}ve;
printf "%s is %d\n", élève => $élève;
                  # \x{E9}le\x{300}ve => $\x{E9}le\x{300}ve;
printf "%s is %d\n", élève => $élève;
                  # e\x{301}l\x{E8}ve => $e\x{301}l\x{E8}ve;
