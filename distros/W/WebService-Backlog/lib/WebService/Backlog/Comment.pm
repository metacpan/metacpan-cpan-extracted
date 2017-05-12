package WebService::Backlog::Comment;

# $Id$

use strict; 
use warnings;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw/id content created_on updated_on created_user/);

use WebService::Backlog::User;

sub created_user {
    my $self = shift;
    $self->SUPER::created_user(WebService::Backlog::User->new(@_)) if (@_);
    return $self->SUPER::created_user;
}

1;
__END__
