# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Test::ServletConfig;

use base qw(Servlet::ServletConfig Servlet::Test::Dummy);
use fields qw(context);
use strict;
use warnings;

use Servlet::Test::Context ();

sub new {
    my $self = shift;
    my $context = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new(@_);

    $self->{context} = $context;

    return $self;
}

sub getServletContext {
    my $self = shift;

    return $self->{context};
}

1;
__END__
