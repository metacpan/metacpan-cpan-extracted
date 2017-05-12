package YAWF::Setup;

use strict;
use warnings;

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

    $self->{yawf}->reply->template('yawf_setup/index');

    if ($self->{yawf}->request->query->{setup_password} and ($self->{yawf}->config->setup_password eq $self->{yawf}->request->query->{setup_password})) {
        $self->{yawf}->reply->{redir} = 'main?SID='.$self->{yawf}->session->{id};
        $self->{yawf}->session->{_setup_loggedin} = 1;
    }

    return 1;
}

1;
