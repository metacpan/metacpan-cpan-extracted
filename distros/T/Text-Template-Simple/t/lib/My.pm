package My;
use strict;
use warnings;

our $VERSION = '0.20';

package Text::Template::Simple::Dummy;
use strict;
use warnings;
# Globals must be defined with vars pragma.
# our() does not work for some reason
use vars qw(%GLOBAL);

%GLOBAL = ( X => 'Y' );

sub hello { return "Dear $_[0], this is a template function!" }

1;

__END__
