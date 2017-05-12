package YAWF::Setup::Main;

use strict;
use warnings;

use YAWF::Setup::Base;

our @ISA = 'YAWF::Setup::Base';

sub new {
    my $class = shift;

    my $self = bless {
        WEB_METHODS => { index => 1 },
        SESSION     => 1,
        LOGIN       => 0,
        @_
    }, $class;

    return $self;
}

sub index {
    my $self = shift;

    return 1 unless $self->auth;

    $self->{yawf}->reply->template('yawf_setup/main');

    return 1;
}

1;
