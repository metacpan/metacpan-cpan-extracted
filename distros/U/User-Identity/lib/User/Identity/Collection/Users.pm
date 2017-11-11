# Copyrights 2003-2017 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see Changes.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
package User::Identity::Collection::Users;
use vars '$VERSION';
$VERSION = '0.98';

use base 'User::Identity::Collection';

use strict;
use warnings;

use User::Identity;


sub new(@)
{   my $class = shift;
    $class->SUPER::new(systems => @_);
}

sub init($)
{   my ($self, $args) = @_;
    $args->{item_type} ||= 'User::Identity';

    $self->SUPER::init($args);

    $self;
}

sub type() { 'people' }

1;

