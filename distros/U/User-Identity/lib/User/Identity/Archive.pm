# Copyrights 2003-2017 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see Changes.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.

package User::Identity::Archive;
use vars '$VERSION';
$VERSION = '0.98';

use base 'User::Identity::Item';

use strict;
use warnings;


sub type { "archive" }


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args) or return;

    if(my $from = delete $args->{from})
    {   $self->from($from) or return;
    }

    $self;
}

#-----------------------------------------


1;

