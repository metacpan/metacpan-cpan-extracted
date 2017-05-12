### Conflict.pm --- Tree::Range::RB, but overwrite-protected  -*- Perl -*-

### Ivan Shmakov, 2013

## To the extent possible under law, the author(s) have dedicated all
## copyright and related and neighboring rights to this software to the
## public domain worldwide.  This software is distributed without any
## warranty.

## You should have received a copy of the CC0 Public Domain Dedication
## along with this software.  If not, see
## <http://creativecommons.org/publicdomain/zero/1.0/>.

### Code:

package Tree::Range::RB::Conflict;

use strict;

our $VERSION = 0.22;

require Tree::Range::conflict;
require Tree::Range::RB;

push (our @ISA, qw (Tree::Range::conflict Tree::Range::RB));

1;

### Emacs trailer
## Local variables:
## coding: us-ascii
## End:
### Conflict.pm ends here
