# Copyrights 2003-2017 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see Changes.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
package User::Identity::System;
use vars '$VERSION';
$VERSION = '0.98';

use base 'User::Identity::Item';

use strict;
use warnings;

use User::Identity;
use Scalar::Util 'weaken';


sub type { "network" }


sub init($)
{   my ($self, $args) = @_;

    $self->SUPER::init($args);
    exists $args->{$_} && ($self->{'UIS_'.$_} = delete $args->{$_})
        foreach qw/hostname location os password username/;

   $self->{UIS_hostname} ||= 'localhost';
   $self;
}


sub hostname() { shift->{UIS_hostname} }


sub username() { shift->{UIS_username} }


sub os() { shift->{UIS_os} }


sub password() { shift->{UIS_password} }


sub location()
{   my $self      = shift;
    my $location  = $self->{MI_location} or return;

    unless(ref $location)
    {   my $user  = $self->user or return;
        $location = $user->find(location => $location);
    }

    $location;
}

1;

