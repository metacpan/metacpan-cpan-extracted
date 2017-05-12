
# A Custom Module::Build subclass ######################################

package WWW::EchoNest::Build;

use 5.010;
use strict;
use warnings;
use Carp;
use parent qw( Module::Build );

use WWW::EchoNest;
BEGIN { our $VERSION = $WWW::EchoNest::VERSION; }

BEGIN { eval { use Module::Build::Debian; }; }

1;

__END__
