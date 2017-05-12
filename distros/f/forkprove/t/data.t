use strict;
use Test::More tests => 1;

my $data = join '', <DATA>;
is $data, "foo\n";

__DATA__
foo
