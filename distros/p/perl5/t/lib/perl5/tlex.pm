package perl5::tlex;
use base 'perl5';

sub imports
{
    strict   => [qw(subs refs vars)],
    warnings => [FATAL => 'all'],           # easier to test
    feature  => ['switch'],                 # means we must be 5.10 or higher
}

1;
