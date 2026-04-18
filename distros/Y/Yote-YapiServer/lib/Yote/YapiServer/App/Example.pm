package Yote::YapiServer::App::Example;

use strict;
use warnings;
use base 'Yote::YapiServer::App::Base';

use Yote::YapiServer::App::Example::Message;

# Inherit base columns and add our own
our %cols = (
    %Yote::YapiServer::App::Base::cols,
    messages => '*ARRAY_*Yote::YapiServer::App::Example::Message',
);

# Method access control
our %METHODS = (
    # Public - no auth required
    getStats      => { public => 1 },
    hello         => { public => 1 },

    # Authenticated users
    getMessages   => { auth => 1 },
    postMessage   => { auth => 1 },

    # Admin only
    clearMessages => { admin_only => 1 },
);

# Field visibility
our %FIELD_ACCESS = (
    %Yote::YapiServer::App::Base::FIELD_ACCESS,
    messages => { auth => 1 },
);

# Public vars exposed on connect
our %PUBLIC_VARS = (
    appName => 'Example App',
    appVersion => '1.0.0',
);

#----------------------------------------------------------------------
# Public methods
#----------------------------------------------------------------------

sub getStats {
    my ($self, $args, $session) = @_;
    my $messages = $self->get_messages // [];
    return 1, {
        messageCount => scalar(@$messages),
        appVersion   => $PUBLIC_VARS{appVersion},
    };
}

sub hello {
    my ($self, $args, $session) = @_;
    my $name = $args->{name} // 'World';
    return 1, "Hello, $name!";
}

#----------------------------------------------------------------------
# Authenticated methods
#----------------------------------------------------------------------

sub getMessages {
    my ($self, $args, $session) = @_;
    my $limit = $args->{limit} // 20;
    my $offset = $args->{offset} // 0;
    
    my $messages = $self->get_messages // [];
    my $total = scalar(@$messages);
    
    # Return slice
    my $end = $offset + $limit - 1;
    $end = $total - 1 if $end >= $total;
    
    my @slice = @{$messages}[$offset..$end];
    
    return 1, {
        messages => \@slice,
        total    => $total,
        limit    => $limit,
        offset   => $offset,
    };
}

sub postMessage {
    my ($self, $args, $session) = @_;
    my $user = $session->get_user;
    
    my $text = $args->{text};
    return 0, "text required" unless $text;
    
    my $store = $self->store;
    my $message = $store->new_obj(
        'Yote::YapiServer::App::Example::Message',
        owner => $user,
        text   => $text,
    );
    
    my $messages = $self->get_messages;
    push @$messages, $message;
    
    return 1, $message;
}

#----------------------------------------------------------------------
# Admin methods
#----------------------------------------------------------------------

sub clearMessages {
    my ($self, $args, $session) = @_;
    @{$self->get_messages} = ();
    return 1, { cleared => 1 };
}

1;

__END__
