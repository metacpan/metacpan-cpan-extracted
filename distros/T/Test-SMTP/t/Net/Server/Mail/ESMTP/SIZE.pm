package Net::Server::Mail::ESMTP::SIZE;

use strict;

use base qw(Net::Server::Mail::ESMTP::Extension);

sub init {
    my ( $self, $parent ) = @_;
    $self->{parent} = $parent;
    return $self;
}

sub keyword {
    return 'SIZE';
}

sub parameter {
    my $self = shift;
    return "1000";
}

1;

