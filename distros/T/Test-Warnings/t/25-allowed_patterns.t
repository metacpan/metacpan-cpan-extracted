use strict;
use warnings;
use Test::More;
use Test::Warnings qw(warnings allow_patterns disallow_patterns :report_warnings);

# warn 'this is a bad warning';

# global effect
allow_patterns qr/bad warning/;
warn 'this bad warning is allowed globally';

{
    my $x = allow_patterns qr/local warning/;
    warn 'this local warning is allowed inside';
}

# warn 'but this local warning is not allowed outside';
warn 'this bad warning is allowed globally';

disallow_patterns qr/bad warning/;
# warn 'this bad warning is not allowed globally';

done_testing;
