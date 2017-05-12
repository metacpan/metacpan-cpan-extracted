package TestHelper;

use Test;
use base 'Exporter';

our @EXPORT = 'hmsf_ok';

sub hmsf_ok
{
    my $tc = shift;
    ok($tc->hours, shift);
    ok($tc->minutes, shift);
    ok($tc->seconds, shift);
    ok($tc->frames, shift);
}

1;
