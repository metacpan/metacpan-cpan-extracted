use FindBin;
use lib "$FindBin::Bin/../lib";

use Path::Tiny;

use Pegex::Parser;
use X11::XRandR::Grammar::Verbose;
use X11::XRandR::Receiver::Verbose;

my $parser = Pegex::Parser->new(
				grammar => X11::XRandR::Grammar::Verbose->new,
				receiver => X11::XRandR::Receiver::Verbose->new
			       );

use Data::Dump;

my $text = path($ARGV[0])->slurp;

dd  $parser->parse( $text );

1;
