use strict;
use warnings;

use Test::More;

use XML::Reader::Testcases 0.48;

my $name = '0010_test_Module.t';

my ($TCntr, $TProg) = @{$XML::Reader::Testcases::TestProg{$name}};

unless (defined $TCntr) {
    die "Test-Abort-0010: Can't find TCntr{'$name'}";
}

unless ($TCntr =~ m{\A \d+ \z}xms) {
    die "Test-Abort-0020: TCntr{'$name'} = '$TCntr' is not numeric";
}

plan tests => $TCntr;

unless (defined $TProg) {
    die "Test-Abort-0030: Can't find TProg{'$name'}";
}

unless (ref($TProg) eq 'CODE') {
    die "Test-Abort-0040: ref(TProg{'$name'}) is '".ref($TProg)."', but should be 'CODE'";
}

$TProg->('XML::Reader::PP');
