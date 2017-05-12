# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Test::HttpRequest;

use base qw(Servlet::Http::HttpServletRequest Servlet::Test::Dummy);
use fields qw(method);
use strict;
use warnings;

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new(@_);

    $self->{method} = undef;

    return $self;
}

sub getMethod {
    my $self = shift;

    return $self->{method} ? $self->{method} : "getMethod";
}

1;
__END__
