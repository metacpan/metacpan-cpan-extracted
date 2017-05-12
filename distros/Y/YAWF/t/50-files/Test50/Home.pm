package Test50::Home;

use strict;
use warnings;

use Test50::FooTab;

sub new {
    my $class = shift;

    my $self = bless {
        WEB_METHODS => { page => 1 },
        SESSION     => 0,
        LOGIN       => 0,
        @_
    }, $class;

    return $self;
}

sub page {
    my $self = shift;

    $self->{yawf}->reply->template('homepage');

    $self->{yawf}->reply->data->{testdata} = 1;

    $self->{yawf}->reply->data->{footab} = Test50::FooTab->new(1);
    $self->{yawf}->reply->data->{foolist} = [Test50::FooTab->list];

    return 1;
}

1;
