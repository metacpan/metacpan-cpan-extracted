# Copyrights 2003-2018 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution User-Identity.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package User::Identity::Archive;
use vars '$VERSION';
$VERSION = '0.99';

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

