# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Test::HttpResponse;

use base qw(Servlet::Http::HttpServletResponse Servlet::Test::Response);
use fields qw(status message headers);
use strict;
use warnings;

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new(@_);

    $self->{status} = undef;
    $self->{message} = undef;
    $self->{headers} = {};

    return $self;
}

sub sendError {
    my $self = shift;
    my $code = shift;
    my $msg = shift;

    $self->setStatus($code);
    $self->{message} = $msg if $msg;

    return "sendError";
}

sub setHeader {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    $self->{headers}->{$name} = [$value] if $name;

    return "setHeader";
}

sub setStatus {
    my $self = shift;
    my $code = shift;

    $self->{status} = $code;

    return "setStatus";
}

1;
__END__
