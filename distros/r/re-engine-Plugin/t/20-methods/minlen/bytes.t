=pod

C<minlen> speaks bytes, not characters.

=cut

use strict;
use Test::More tests => 3;
use re::engine::Plugin (
    comp => sub { shift->minlen(5) },
    exec => sub {
        my ($re, $str) = @_;
        pass "Called with $str";
    },
);

my $str = "ævar";
is(length $str, 5, "$str is 5 char long"); # Chars
$str =~ /pattern/; # no ->exec

chop $str;
is(length $str, 4, "$str is 4 char long"); # Chars
$str =~ /pattern/; # yes ->exec
