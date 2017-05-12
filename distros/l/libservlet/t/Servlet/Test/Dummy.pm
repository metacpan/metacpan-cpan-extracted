# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Test::Dummy;

use fields qw();
use strict;
use warnings;

# simple dummy base class
# for all methods other than new(), simply return the method name

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;

    return $self;
}

sub AUTOLOAD {
    my $self = shift;
    no strict;

    my $method = $AUTOLOAD;
    return 1 if $method =~ /::DESTROY$/;

    $method =~ s/^.+::([^:]+)$/$1/;

    return $method;
}

1;
__END__
