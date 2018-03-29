use FindBin;
use lib "$FindBin::Bin/../lib";

use X11::XRandR::State;

use Data::Dump;

my $state = X11::XRandR::State->query;

dd $state;
