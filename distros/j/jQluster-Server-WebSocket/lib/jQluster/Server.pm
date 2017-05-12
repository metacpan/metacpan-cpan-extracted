package jQluster::Server;
use 5.10.0;
use strict;
use warnings;
use Carp;
use Data::UUID;

our $VERSION = "0.03";

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        id_generator => Data::UUID->new,
        registry => {},
        uids_for_remote_node_id => {},
        logger => $args{logger} // sub { },
    }, $class;
    return $self;
}

sub _generate_message_id {
    my ($self) = @_;
    return $self->{id_generator}->create_str();
}

sub _log {
    my ($self, $level, $msg) = @_;
    $self->{logger}->($level, $msg);
}

sub register {
    my ($self, %args) = @_;
    foreach my $key (qw(unique_id message sender)) {
        croak "$key parameter is mandatory" if not defined $args{$key};
    }
    foreach my $msg_key (qw(message_id from message_type)) {
        if(!defined($args{message}{$msg_key})) {
            croak "The register message does not have $msg_key field. Something is wrong.";
        }
    }
    if($args{message}{message_type} ne "register") {
        croak "Message type is $args{message}{message_type}, not 'register'. Something is wrong.";
    }
    my %reg_entry = (
        unique_id => $args{unique_id},
        sender => $args{sender},
        remote_node_id => $args{message}{from}
    );
    if(exists $self->{registry}{$reg_entry{unique_id}}) {
        croak "Duplicate registration for unique ID: $reg_entry{unique_id}";
    }
    $self->{registry}{$reg_entry{unique_id}} = \%reg_entry;
    $self->{uids_for_remote_node_id}{$reg_entry{remote_node_id}}{$reg_entry{unique_id}} = 1;
    $self->_log(info => "Accept registration: unique_id = $reg_entry{unique_id}, remote_node_id = $reg_entry{remote_node_id}");

    $self->distribute({
        message_id => $self->_generate_message_id(),
        message_type => "register_reply",
        from => undef, to => $reg_entry{remote_node_id},
        body => { error => undef, in_reply_to => $args{message}{message_id} }
    });
}

sub unregister {
    my ($self, $unique_id) = @_;
    my $entry = delete $self->{registry}{$unique_id};
    return if !defined($entry);
    delete $self->{uids_for_remote_node_id}{$entry->{remote_node_id}}{$entry->{unique_id}};
    $self->_log(info => "Unregister: unique_id = $unique_id, remote_node_id = $entry->{remote_node_id}");
}

my %REPLY_MESSAGE_TYPE_FOR = (
    select_and_get => "select_and_get_reply",
    select_and_listen => "select_and_listen_reply"
);

sub _try_reply_error_to {
    my ($self, $orig_message, $error) = @_;
    my $reply_message_type = $REPLY_MESSAGE_TYPE_FOR{$orig_message->{message_type}};
    if(!defined($reply_message_type)) {
        $self->_log("error", "Unknown message type: $orig_message->{message_type}: cannot reply to it.");
        return;
    }
    $self->distribute({
        message_id => $self->_generate_message_id(),
        message_type => $reply_message_type,
        from => undef, to => $orig_message->{from},
        body => { error => $error, in_reply_to => $orig_message->{message_id} }
    });
}

sub distribute {
    my ($self, $message) = @_;
    my $to = $message->{to};
    if(!defined($to)) {
        return;
    }
    my $uid_map = $self->{uids_for_remote_node_id}{$to};
    if(!defined($uid_map) || !%$uid_map) {
        $self->_try_reply_error_to($message, "Target remote node ($to) does not exist.");
        return;
    }
    foreach my $uid (keys %$uid_map) {
        my $entry = $self->{registry}{$uid};
        if(!defined($entry)) {
            $self->_log("error", "UID registry has a key for $uid, but it does not map to an entry object. Something is wrong.");
            next;
        }
        $entry->{sender}->($message);
    }
}

1;

__END__

=head1 NAME

jQluster::Server - jQluster tranport server independent of underlying connection implementation

=head1 SYNOPSIS

    my @logs = ();
    my $server = jQluster::Server->new(
        logger => sub {  ## OPTIONAL
            my ($level, $msg) = @_;
            push(@logs, [$level, $msg]);
        }
    );
    
    $server->register(
        unique_id => "global unique ID for the connection",
        message => $registration_message,
        sender => sub {
            my ($message) = @_;
            $some_transport->send($message);
        }
    );
    
    $server->distribute($message);
    
    $server->unregister($unique_id);

=head1 DESCRIPTION

L<jQluster::Server> is part of jQluster project. To learn more about jQluster, visit L<https://github.com/debug-ito/jQluster>.

L<jQluster::Server> accepts connections from jQluster client nodes,
receives messages from these nodes and distributes the messages to
appropriate destination nodes.

L<jQluster::Server> is independent of connection implementations. It
just tells the destination connection's sender routine that it has
incoming messages to the connection.


=head1 CLASS METHODS

=head2 $server = jQluster::Server->new(%args)

The constructor. Fields in C<%args> are:

=over

=item C<logger> => CODE (optional, default: log nothing)

A subroutine reference that is called when the C<$server> wants to log
something.

The C<$logger> is called like

    $logger->($level, $message)

where C<$level> is a log level string such as "info", "warning",
"error" etc.  C<$message> is the log message string.

=back

=head1 OBJECT METHODS

=head2 $server->register(%args)

Register a new jQluster connection to a client node.

Fields in C<%args> are:

=over

=item C<unique_id> => ID (mandatory)

The ID for the new connection. The ID must be unique within the
C<$server>.  If you try to register an ID that is already registered,
it croaks.

=item C<message> => jQluster MESSAGE HASH (mandatory)

A jQluster message for registration.  The message is usually created
by a jQluster client node.

=item C<sender> => CODE (mandatory)

A subroutine reference that is called when the C<$server> sends a
message to this connection.

The C<$sender> is called like

    $sender->($jqluster_message)

where C<$jqluster_message> is a jQluster message object. It's a plain
hash-ref. It's up to the C<$sender> how to deliver the message to the
client node.

=back

=head2 $server->distribute($message)

Distirbute the given jQluster message to destination nodes.

C<$message> is a jQluster message object. It's a plain hash-ref.


=head2 $server->unregister($unique_id)

Unregister a connection to a client node.

C<$unique_id> is the unique ID you give when calling C<register()>
method.  If C<$unique_id> is not registered, it does nothing.


=head1 AUTHOR

Toshio Ito C<< toshioito [at] cpan.org >>

