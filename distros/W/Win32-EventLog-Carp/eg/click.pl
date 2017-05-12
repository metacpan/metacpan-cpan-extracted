use strict;
use warnings;

use Win32::EventLog::Carp qw(croak click);

my $num = shift || 144;
$num < 0 and croak "Attempted to find square root of $num\n";

# to STDERR and the Application Event Log
click("Square root of $num is " . sqrt($num));
