package RPC;
use Msg;
use strict;
use Carp;
@RPC::ISA = qw(Msg);
use FreezeThaw qw(freeze thaw);

#-----------------------------------------------------------------
# Server side
sub new_server {
    my ($pkg, $my_host, $my_port) = @_;
    return $pkg->SUPER::new_server($my_host, $my_port, sub {$pkg->_login(@_)});
}

sub _login {
    return \&_incoming_msg;
}

sub _incoming_msg {
    my ($conn, $msg, $err) = @_;
    return if ($err);   # Need better error handling.
    return unless defined($msg);
    my ($dir, $id, @args) = thaw ($msg);
    my ($result, @results);
    if ($dir eq '>') {
        my $gimme = shift @args;
        my $sub_name = shift @args;
        # Incoming msg. (outgoing msg from client, that is)
        eval {
            no strict 'refs';  # Because we call the subroutine using
                               # a symbolic reference
            if ($gimme eq 'a') {  # Want an array back
                @results = &{$sub_name} (@args); 
            } else {
                $result = &{$sub_name} (@args);
            }
        };
        if ($@) {
            $msg = bless \$@, "RPC::Error";
            $msg = freeze('<', $id, $msg);
        } elsif ($gimme eq 'a') {
            $msg = freeze('<', $id, @results);
        } else {
            $msg = freeze('<', $id, $result);
        }
        $conn->send_later($msg);
    } else {
        # Response to our message
        $conn->{rcvd}->{$id} = \@args;
    }
}


#-----------------------------------------------------------------
# Client side
sub connect {
   my ($pkg, $host, $port) = @_;
   my $conn = $pkg->SUPER::connect($host,$port, \&_incoming_msg);
   return $conn;
}

my $send_err = 0;
sub handle_send_err {
   $send_err = $!;
}

my $g_msg_id = 0;
sub rpc {
    my $conn = shift;
    my $subname = shift;
    
    $subname = (caller() . '::' . $subname) unless $subname =~ /:/;
    my $gimme = wantarray ?  'a' : 's';  # Array or scalar
    my $msg_id = ++$g_msg_id;
    my $serialized_msg = freeze ('>', $msg_id, $gimme, $subname, @_);

    # Send and Receive
    $conn->send_later ($serialized_msg);
    if ($send_err) {
        die "RPC Error: $!\n";
    }

    do {
        Msg->event_loop(1); # Dispatch other messages until we get a response
    } until (exists $conn->{rcvd}->{$msg_id} || $send_err);
 
    # Dequeue message
    my $rl_retargs = delete $conn->{rcvd}->{$msg_id}; # ref to list

    if (ref($rl_retargs->[0]) eq 'RPC::Error') {
        die ${$rl_retargs->[0]};
    }
    wantarray ? @$rl_retargs : $rl_retargs->[0];
}

1;
