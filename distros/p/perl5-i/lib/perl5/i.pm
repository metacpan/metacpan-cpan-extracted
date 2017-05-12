use strict; use warnings;
package perl5::i;
our $VERSION = '0.12';

use perl5;
# use perl5i;
use perl5i::latest;

use base 'perl5';

use constant imports => ('perl5i::latest');

1;
