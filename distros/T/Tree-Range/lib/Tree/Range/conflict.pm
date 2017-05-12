### conflict.pm --- Protect ranges from being written over  -*- Perl -*-

### Ivan Shmakov, 2013

## To the extent possible under law, the author(s) have dedicated all
## copyright and related and neighboring rights to this software to the
## public domain worldwide.  This software is distributed without any
## warranty.

## You should have received a copy of the CC0 Public Domain Dedication
## along with this software.  If not, see
## <http://creativecommons.org/publicdomain/zero/1.0/>.

### Code:

package Tree::Range::conflict;

use mro;
use strict;

our $VERSION = 0.22;

require Carp;

sub range_set {
    my ($self, $lower, $upper, $value) = @_;
    Carp::croak ("Range (", $lower, " to ", $upper,
                 ") is already associated with a value")
        unless ($self->range_free_p ($lower, $upper));
    ## .
    $self->next::method ($lower, $upper, $value);
}

1;

### Emacs trailer
## Local variables:
## coding: us-ascii
## End:
### conflict.pm ends here
