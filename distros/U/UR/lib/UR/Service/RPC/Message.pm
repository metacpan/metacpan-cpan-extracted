package UR::Service::RPC::Message;

use UR;
use FreezeThaw;
use IO::Select;

use strict;
use warnings;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Service::RPC::Message',
    has => [
        target_class => { is => 'String' },
        method_name  => { is => 'String' },
    ],
    has_optional => [
        #arg_list     => { is => 'ARRAY' },
        params     => { is => 'Object', is_many => 1 },
        return_values => { is => 'Object', is_many => 1 },
        'wantarray'  => { is => 'Integer' },
        fh           => { is => 'IO::Handle' },
        exception    => { is => 'String' },
    ],
    is_transactional => 0,
);


sub create {
    my($class,%params) = @_;

    foreach my $key ( 'params', 'return_values' ) {
        if (!$params{$key}) {
            $params{$key} = [];
        } elsif (ref($params{$key}) ne 'ARRAY') {
            $params{$key} = [ $params{$key} ];
        }
    }

    return $class->SUPER::create(%params);
}

    


sub send {
    my $self = shift;
    my $fh = shift;

    $fh ||= $self->fh;

    my %struct;
    foreach my $key ( qw (target_class method_name params wantarray return_values exception) ) {
         $struct{$key} = $self->{$key};
    }

    my $string = FreezeThaw::freeze(\%struct);
    $string = pack('N', length($string)) . $string;

    my $len = length($string);
    my $sent = 0;
    while($sent < $len) {
        my $wrote = $fh->syswrite($string, $len - $sent, $sent);

        if ($wrote) {
            $sent += $wrote;
        } else {
            # The filehandle closed for some reason
            $fh->close;
            return undef;
        }
    }

    return $sent;
}



sub recv {
    my($class, $fh, $timeout) = @_;

    # You can also call recv on a message object previously created
    if (ref($class) && $class->isa('UR::Service::RPC::Message')) {
        my $fh = $class->fh;
        $class = ref($class);
        return $class->recv($fh);
    }

    if (@_ < 3) {  # # if they didn't specify a timeout
        $timeout = 5; # Default wait 5 sec
    }

    my $select = IO::Select->new($fh);

    # read in the message len, 4 chars
    my $msglen;
    my $numchars = 0;
    while ($numchars < 4) {
        unless ($select->can_read($timeout)) {
            $class->warning_message("Can't get message length, timed out");
            return;
        }

        my $read = $fh->sysread($msglen, 4-$numchars, $numchars);

        unless ($read) {
            $class->warning_message("Can't get message length: $!");
            return;
        }

        $numchars += $read;
    }

    $msglen = unpack('N', $msglen);

    my $string = '';
    $numchars = 0;
    while ($numchars < $msglen) {
        unless ($select->can_read($timeout)) {
            $class->warning_message("Timed out reading message after $numchars bytes");
            return;
        }

        my $read = $fh->sysread($string, $msglen - $numchars, $numchars);

        unless($read) {
            $class->warning_message("Error reading message after $numchars bytes: $!");
            return;
        }

        $numchars += $read;
    }

    my($struct) = FreezeThaw::thaw($string);

    my $obj = $class->create(%$struct, fh => $fh);

    return $obj;
}
        
 

1;

=pod

=head1 NAME

UR::Service::RPC::Message - Serializable object appropriate for sending RPC messages

=head1 SYNOPSIS

  my $msg = UR::Service::RPC::Message->create(
                           target_class => 'URT::RPC::Thingy',
                           method_name  => 'join',
                           params       => ['-', @join_args],
                           'wantarray'  => 0,
                         );
  $msg->send($fh);

  my $resp = UR::Service::RPC::Message->recv($fh, 5);

=head1 DESCRIPTION

This class is used as a message-passing interface by the RPC service modules.

=head1 PROPERTIES

These properties should be filled in by the initiating caller

=over 4

=item method_name => Text

The name of the subroutine the initiator whishes to call.

=item target_class => Text

The namespace the initiator wants the subroutine to be called in

=item params => ARRAY

List of parameters to pass to the subroutine

=item wantarray => Boolean

What wantarray() context the subroutine should be called in.

=back

These properties are assigned after the RPC call to the subroutine

=over 4

=item return_values => ARRAY

List of values returned by the subroutine

=item exception

On the receiving side, the subroutine is called within an eval.  If there
was an exception, C<exception> stores the value of $@, or the empty string.
The receiving side should also fill-in C<exception> if there was an
authentication failure.

=item fh

C<recv> fills this in with the file handle the message was read from.

=back

=head1 METHODS

=over 4

=item send

  $bytes = $msg->send($fh);

Serializes the Message object with FreezeThaw and writes the data to the
filehandle $fh.  Returns the number of bytes written.  $bytes will be
false if there was an error.

=item recv

  $response = UR::Service::RPC::Message->recv($fh,$timeout);

  $response = $msg->recv();

Reads a serialized Message from the filehandle and constructs a Message
object that is then returned to the caller.  In the first case, it reads
from the given filehandle, waiting a maximum of $timeout seconds with
select before giving up.  In the second case, it reads from whatever
filehandle is stored in $msg to read data from.

=back

=head1 SEE ALSO

UR::Service::RPC::Server, UR::Service::RPC::Executor

=cut


