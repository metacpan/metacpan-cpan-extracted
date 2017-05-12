use strict;
use warnings;

use WebDriver::Tiny;
use Test::More tests => 2;

my $warn;

$SIG{__WARN__} = sub { $warn .= $_[0] };

eval { WebDriver::Tiny->new( port => 1 ) };

like $@, qr/^WebDriver::Tiny - Could not connect to 'localhost:1'/,
    '->new correctly throws';

is $warn, undef, 'No additional warning in cleanup';
