# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Test::Response;

use base qw(Servlet::ServletResponse Servlet::Test::Dummy);
use fields qw(contentType);
use strict;
use warnings;

use Servlet::Test::OutputHandle ();

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new(@_);

    $self->{contentType} = undef;

    return $self;
}

sub getOutputHandle {
    my $self = shift;

    return Servlet::Test::OutputHandle->new();
}

sub setContentType {
    my $self = shift;
    my $type = shift;

    $self->{contentType} = $type;

    return "setContentType";
}

1;
__END__
