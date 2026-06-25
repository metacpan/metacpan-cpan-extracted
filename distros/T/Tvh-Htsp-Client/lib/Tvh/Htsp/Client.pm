package Tvh::Htsp::Client;
# Tvheadend HTSP client library written in perl
# https://docs.tvheadend.org/documentation/development/htsp
use strict;
use warnings;
use v5.28;
use namespace::autoclean;
use IO::Socket qw(AF_INET SOCK_STREAM);
use LooksLike;
use List::Util qw(min max);
our $VERSION     = '0.06';    # set the version for version checking
sub new {
  my ($class, $args) = @_;
  my $self = {
    host => $args->{host} // 'localhost',
    port => $args->{port} // 9982,
    debug_info => $args->{debug_info} // 0,
    no_client => $args->{no_client} // 0,
    epgdb_v3 => $args->{epgdb_v3} // 0,
    db => [],
  };
  $self->{template} = $self->{epgdb_v3} ? "w" : "N";    # unpack template for length of htsp messages to be deserialised
  unless ($self->{no_client}) {
    no warnings 'once';
    $self->{client} = IO::Socket->new(
      Domain => AF_INET,
      Type => SOCK_STREAM,
      proto => 'tcp',
      PeerHost => "$self->{host}",
      PeerPort => $self->{port},
    ) || die "Error ".(caller(0))[3].": can't open socket: $IO::Socket::errstr";
    # my $peer_addr = $self->{client}->connected();
    # if ($peer_addr) { say "Connected to $peer_addr"; }
  }
  return bless $self, $class;
}
sub DESTROY {
  # close IO::Socket
  my $self = shift;
  $self->{client}->close() if $self->{client};
}
sub getChanUuidId {
  # Get all channel uuid and ID
  my $self = shift;
  # Enable async to find channel uuid and ID
  $self->htsp_send({'method' => 'enableAsyncMetadata'});
  # Process messages
  my $chan_uuid_id = {};
  while (1) {
    my $reply = $self->htsp_recv();
    if ($reply->{'method'}) {
      if ($reply->{'method'} eq 'channelAdd') {
        $chan_uuid_id->{$reply->{'channelIdStr'}} = $reply->{'channelId'};
      }
      elsif ($reply->{'method'} eq 'initialSyncCompleted') {
        last;
      }
    }
  }
  return $chan_uuid_id;
}
sub getChanNamId {
  # Get 'channelName' and channelId'
  my $self = shift;
  my $channel = shift;
  my ($chan_name, $chan_id);
  if (LooksLike::integer($channel) and $channel > 100_000_000) {
    # $channel > 100_000_000 must be a 'channelId'
    $chan_id = $channel;
    # get channel name
    my $reply = $self->htsp_send_recv({'method' => 'getChannel', 'channelId' => $channel});
    if ($reply->{'channelName'} and $reply->{'channelId'} eq "$channel") {
      $chan_name = $reply->{'channelName'};
    }
    else {die "Error ".(caller(0))[3].": channelId '$channel' not found -- ".join(', ', map {"'$_ => $reply->{$_}'"} (sort keys $reply->%*))}
  }
  else {
    # Enable async to find 'channelId' from 'channelName' or 'channelNumber'
    $self->htsp_send({'method' => 'enableAsyncMetadata'});
    # Process messages
    my $chan_nam_id = {};
    my $chan_num_id = {};
    my $chan_num_nam = {};
    while (1) {
      my $reply = $self->htsp_recv();
      if ($reply->{'method'}) {
        if ($reply->{'method'} eq 'channelAdd') {
          $chan_nam_id->{$reply->{'channelName'}} = $reply->{'channelId'};
          $chan_num_id->{$reply->{'channelNumber'}} = $reply->{'channelId'};
          $chan_num_nam->{$reply->{'channelNumber'}} = $reply->{'channelName'};
        }
        elsif ($reply->{'method'} eq 'initialSyncCompleted') {
          last;
        }
      }
    }
    if ($chan_nam_id->{$channel}) {
      # found 'channelName'
      $chan_name = $channel;
      $chan_id = $chan_nam_id->{$channel};
    }
    elsif ($chan_num_id->{$channel}) {
      # found 'channelNumber'
      $chan_name = $chan_num_nam->{$channel};
      $chan_id = $chan_num_id->{$channel};
    }
    elsif (LooksLike::integer($channel)) {
      # 'channelNumber' not found
      my $chan_num_sorted = join(', ', map {"'$_ $chan_num_nam->{$_}'"} (sort {$a <=> $b} keys $chan_num_nam->%*));
      die ("Error ".(caller(0))[3].": channelNumber '$channel' not found in [ $chan_num_sorted ]");
    }
    else {
      # 'channelName' not found
      my $chan_nam_sorted = join(', ', map {"'$_ $chan_num_nam->{$_}'"} (sort {$a <=> $b} keys $chan_num_nam->%*));
      die ("Error ".(caller(0))[3].": channelName '$channel' not found in [ $chan_nam_sorted ]");
    }
  }
  return ($chan_name, $chan_id);
}
sub htsp_send_recv {
  # send and receive HTSP message
  my $self = shift;
  $self->htsp_send(shift);    # serialise and send
  return $self->htsp_recv();    # receive and deserialise
}
sub htsp_send {
  # send HTSP message
  my $self = shift;
  my $msg = shift;
  state $i = 0;
  $i++;
  $self->{msg} = $msg;
  my $htspmsg = $self->htsmsg_serialise($msg);    # serialise
  say STDERR join(' ',(unpack("H*",$htspmsg) =~ /../g)) if $self->{debug_info};    # convert serialised message to H = hex string (high nybble first)
  say "$i sending '$msg->{'method'}' -- ".(caller(0))[3] if $self->{debug_info};
  my $size = $self->{client}->send($htspmsg);
  say "  sent data of length $size" if $self->{debug_info};
  $self->htsmsg_deserialise(\$htspmsg) if $self->{debug_info};    # deserialise
  return $size;
}
sub htsp_recv {
  # receive HTSP message
  my $self = shift;
  my ($buffer, $length) = ('', 0);
  state $rest = '';
  state $i = 0;
  $i++;
  $buffer = $rest;    # take over the 'rest' = remaining buffer from the previous call
  $length = unpack("N",substr($buffer,0,4,'')) if ($buffer);    # Total length of message = 4 byte integer "network" big-endian byte-order
  while (not $buffer) {
    # Determine beginning and length of the message
    $self->{client}->recv($buffer, 4096) // die "Error ".(caller(0))[3].": from socket: $IO::Socket::errstr";    # get bytes from HTSP server
    die "Error ".(caller(0))[3].": received '$buffer' of length ".length($buffer) unless $buffer;
    say "$i received data of length ".length($buffer)." -- ".(caller(0))[3] if $self->{debug_info};
    say STDERR join(' ',(unpack("H*",$buffer) =~ /../g)) if $self->{debug_info};    # convert serialised message to H = hex string (high nybble first)
    while ($length == 0 and $buffer) {
      # enableAsyncMetadata first transmits a Null-Byte, we need to get rid of this
      $length = unpack("N",substr($buffer,0,4,''));    # Total length of message = 4 byte integer "network" big-endian byte-order
      say "  message length $length" if $self->{debug_info};
    }
    return({ response => 0 }) if ($length == 0 and not $buffer and $self->{msg}->{method} ne "enableAsyncMetadata");
  }
  if ($length > 10_000_000 and $self->{debug_info}) {
    # a likely incorrect excessive length, because the bytes are not being interpreted correctly
    say STDERR join(' ',(unpack("H*",$buffer) =~ /../g));    # convert serialised message to H = hex string (high nybble first)
    die ("Error ".(caller(0))[3].": message length '$length' > 10_000_000, not realistic");
  }
  while ($length > length($buffer)) {
    # the message length requires more bytes
    say "  message length $length > ".length($buffer)." length(\$buffer)" if $self->{debug_info};
    $self->{client}->recv(my $buffer0, min($length-length($buffer),4096)) // die "Error ".(caller(0))[3].": from socket: $IO::Socket::errstr";    # get bytes from HTSP server
    die "Error ".(caller(0))[3].": received '$buffer0' of length ".length($buffer0) unless $buffer0;
    say "  received data of length ".length($buffer0) if $self->{debug_info};
    say STDERR join(' ',(unpack("H*",$buffer0) =~ /../g)) if $self->{debug_info};    # convert serialised message to H = hex string (high nybble first)
    $buffer .= $buffer0;    # append the received bytes to the response '$buffer'
  }
  if ($length <= length($buffer)) {
    # the response contains additional bytes of the subsequent message
    say "  message length $length <= ".length($buffer)." length(\$buffer)" if $self->{debug_info};
    $rest = $buffer;    # transfer response to '$rest'
    $buffer = substr($rest,0,$length,'');    # shorten response '$buffer' to the required message '$length', keep the remainder in '$rest' for the subsequent call to 'htsp_recv'
  }
  say "$i buffer length -- ".length($buffer)." -- ".(caller(0))[3] if $self->{debug_info};
  my $htspmsg = pack("N",$length).$buffer;    # prepend the previously removed 4 bytes with the message length
  return $self->htsmsg_deserialise(\$htspmsg);    # deserialise the message an return it
}
sub htsmsg_serialise {
  # serialise a HTSP message
  my $self = shift;
  my $msg = shift;
  state $sub_message = 0;
  state $i=0;
  say ++$i." -- ".(caller(0))[3] if $self->{debug_info} and not $sub_message;
  my $htspmsg = '';
  my ($ishash, @keys, @vals);
  if (ref $msg eq "HASH") {
    $ishash = 1;
    @keys = keys $msg->%*;
    @vals = values $msg->%*;
  }
  elsif (ref $msg eq "ARRAY") {
    die ("Error ".(caller(0))[3].": root message must be of type 'Map' = a 'HASH' reference, not '".ref($msg)."'") unless $sub_message;
    $ishash = 0;
    @keys = keys $msg->@*;
    @vals = values $msg->@*;
  }
  else {
    die ("Error ".(caller(0))[3].": message must be a 'HASH' or 'ARRAY' reference, not '".ref($msg)."'");
  }
  for my $key (@keys) {
    my $val = shift @vals;
    say '  'x($sub_message+1)."$key => $val" if $self->{debug_info};
    if (ref $val eq "HASH") {
      # Map = 1 = Sub message of type map
      my $type = pack("C",1);    # 1 byte integer
      my $namelength = $ishash ? pack("C",length($key)) : chr(0);    # 1 byte integer
      my $name = $ishash ? $key : '';   # string
      $sub_message++;
      my $data = $self->htsmsg_serialise($val);
      $sub_message--;
      my $datalength = pack("N",length($data));    # 4 byte integer "network" big-endian byte-order
      $htspmsg .= $type.$namelength.$datalength.$name.$data;
    }
    elsif (ref $val eq "ARRAY") {
      # List = 5 = Sub message of type list
      my $type = pack("C",5);    # 1 byte integer
      my $namelength = $ishash ? pack("C",length($key)) : chr(0);    # 1 byte integer
      my $name = $ishash ? $key : '';   # string
      $sub_message++;
      my $data = $self->htsmsg_serialise($val);
      $sub_message--;
      my $datalength = pack("N",length($data));    # 4 byte integer "network" big-endian byte-order
      $htspmsg .= $type.$namelength.$datalength.$name.$data;
    }
    elsif (ref $val ne "") {
      die ("Error ".(caller(0))[3].": field value cannot be a reference of type '".ref($val)."'");
    }
    elsif (LooksLike::integer($val)) {
      # S64 = 2 = Signed 64bit integer
      my $type = pack("C",2);    # 1 byte integer
      my $namelength = $ishash ? pack("C",length($key)) : chr(0);    # 1 byte integer
      my $name = $ishash ? $key : '';   # string
      my $data = pack("q<",$val);    # 64 bit = 8 byte signed integer little-endian byte-order -> q = signed quad (64-bit) value
      # Integers are encoded using a very simple variable length encoding. All leading bytes that are 0 is discarded.
      $data =~ s/\0{1,7}$//;    # remove Null-Byte from the end, keep a first one
      my $datalength = pack("N",length($data));    # 4 byte integer "network" big-endian byte-order
      $htspmsg .= $type.$namelength.$datalength.$name.$data;
    }
    elsif (LooksLike::numeric($val)) {
      # Dbl = 6 = Double precision floating point
      my $type = pack("C",6);    # 1 byte integer
      my $namelength = $ishash ? pack("C",length($key)) : chr(0);    # 1 byte integer
      my $name = $ishash ? $key : '';   # string
      my $data = pack("d",$val);    # d = A double-precision float in native format
      my $datalength = pack("N",length($data));    # 4 byte integer "network" big-endian byte-order
      $htspmsg .= $type.$namelength.$datalength.$name.$data;
    }
    else {
      # Str = 3 = UTF-8 encoded string
      my $type = pack("C",3);    # 1 byte integer
      my $namelength = $ishash ? pack("C",length($key)) : chr(0);    # 1 byte integer
      my $name = $ishash ? $key : '';   # string
      my $data = $val;    # UTF-8 encoded string
      my $datalength = pack("N",length($data));    # 4 byte integer "network" big-endian byte-order
      $htspmsg .= $type.$namelength.$datalength.$name.$data;
    }
  }
  # say '  'x($sub_message+1)."sub_message = ".$sub_message if $self->{debug_info};
                                   # in case of root message prepend message length
  return $sub_message ? $htspmsg : pack("N",length($htspmsg)).$htspmsg;
}
sub htsmsg_deserialise {
  # deserialise a HTSP message
  # https://docs.tvheadend.org/documentation/development/htsp/htsmsg-binary-format
  my $self = shift;
  my $htsmsg = shift;    # reference to the message to be deserialised
  state $i=0;
  my $bd={};    # root message must be of type 'Map' = a 'HASH' reference
  # Root body
  # Length of Root body = 4 byte integer = Total length of message (not including this length field itself)
  my $length = $self->htsmsg_message_length($htsmsg);    # Total length of message
  say ++$i." -- $length -- ".(caller(0))[3] if $self->{debug_info};
  my $body = substr($$htsmsg,0,$length,'');    # keep additional length in '$htsmsg' for any subsequent messages
  # Body = HTSMSG-Field * N = Fields in the root body
  while (length $body) {
    $self->htsmsg_field_deserialise (\$body, $bd);
  }
  push($self->{db}->@*, $bd) if $self->{debug_info};
  return $bd;
}
sub htsmsg_field_deserialise {
  # deserialise a HTSP field
  my $self = shift;
  my $htsmsg = shift;
  my $bd = shift;
  state $indent=1;
  # process HTSMSG-Field
  # Type = 1 byte integer = Type of field by ID
  my $type = unpack("C",substr($$htsmsg,0,1,''));
  # Namelength = 1 byte integer = Length of name of field. If a field is part of a list message this must be 0
  my $namelength = unpack("C",substr($$htsmsg,0,1,''));
  # Datalength = 4 byte integer = Length of field data
  my $datalength = $self->htsmsg_message_length($htsmsg);    # determine data length
  # Name = N bytes = Field name, length as specified by Namelength
  my $name = substr($$htsmsg,0,$namelength,'');
  # Data = N bytes = Field payload
  my $data = substr($$htsmsg,0,$datalength,'');
  if ($type == 1) {
    # Map = 1 = Sub message of type map
    say '  'x$indent."$type $namelength $datalength '$name'" if $self->{debug_info};
    my $ref;
    if (ref $bd eq "HASH") {
      $bd->{"$name"} = {} unless $bd->{"$name"};
      $ref = $bd->{"$name"};
    }
    elsif (ref $bd eq "ARRAY") {
      push($bd->@*, {});
      $ref = $bd->@[-1];
    }
    while (length $data) {
      $indent++;
      $self->htsmsg_field_deserialise (\$data, $ref) ;
      $indent--;
    }
  }
  elsif ($type == 2) {
    # S64 = 2 = Signed 64bit integer
    # Integers are encoded using a very simple variable length encoding. All leading bytes that are 0 is discarded.
    while (length($data) < 8) {$data .= chr(0);}    # fill up with Null-Bytes
    $data = unpack("q<",$data);    # 64 bit = 8 byte signed integer little-endian byte-order -> q = signed quad (64-bit) value
    if (ref $bd eq "HASH") {
      $bd->{"$name"} = $data;
    }
    elsif (ref $bd eq "ARRAY") {
      push($bd->@*, $data);
    }
    say '  'x$indent."$type $namelength $datalength '$name' '$data'" if $self->{debug_info};
  }
  elsif ($type == 3) {
    # Str = 3 = UTF-8 encoded string
    # utf8::decode($data);
    if (ref $bd eq "HASH") {
      $bd->{"$name"} = $data;
    }
    elsif (ref $bd eq "ARRAY") {
      push($bd->@*, $data);
    }
    say '  'x$indent."$type $namelength $datalength '$name' '$data'" if $self->{debug_info};
  }
  elsif ($type == 4) {
    # Bin = 4 = Binary blob
    $data = unpack("H*",$data);    # convert binary blob to H = hex string (high nybble first)
    if (ref $bd eq "HASH") {
      $bd->{"$name"} = $data;
    }
    elsif (ref $bd eq "ARRAY") {
      push($bd->@*, $data);
    }
    say '  'x$indent."$type $namelength $datalength '$name' '$data'" if $self->{debug_info};
  }
  elsif ($type == 5) {
    # List = 5 = Sub message of type list
    say '  'x$indent."$type $namelength $datalength '$name'" if $self->{debug_info};
    my $ref;
    if (ref $bd eq "HASH") {
      $bd->{"$name"} = [] unless $bd->{"$name"};
      $ref = $bd->{"$name"};
    }
    elsif (ref $bd eq "ARRAY") {
      push($bd->@*, []);
      $ref = $bd->@[-1];
    }
    while (length $data) {
      $indent++;
      $self->htsmsg_field_deserialise(\$data, $ref);
      $indent--;
    }
  }
  elsif ($type == 7) {
    # Bool = 7 = Boolean
    $data = $datalength ? unpack("C",$data) : 0;    # C = 1 byte unsigned char
    if (ref $bd eq "HASH") {
      $bd->{"$name"} = $data;
    }
    elsif (ref $bd eq "ARRAY") {
      push($bd->@*, $data);
    }
    say '  'x$indent."$type $namelength $datalength '$name' '$data'" if $self->{debug_info};
  }
  elsif ($type == 8) {
    # UUID = 8 = 64 bit UUID in binary format
    $data = unpack("H*",$data);    # 16 byte = 128 bit binary number -> H = hex string (high nybble first)
    if (ref $bd eq "HASH") {
      $bd->{"$name"} = $data;
    }
    elsif (ref $bd eq "ARRAY") {
      push($bd->@*, $data);
    }
    say '  'x$indent."$type $namelength $datalength '$name' '$data'" if $self->{debug_info};
  }
  elsif ($type == 6) {
    # Dbl = 6 = Double precision floating point
    $data = unpack("d",$data);    # d = A double-precision float in native format
    if (ref $bd eq "HASH") {
      $bd->{"$name"} = $data;
    }
    elsif (ref $bd eq "ARRAY") {
      push($bd->@*, $data);
    }
    say '  'x$indent."$type $namelength $datalength '$name' '$data'" if $self->{debug_info};
  }
  else {
    die ("Error ".(caller(0))[3].": encountered unknown field type ID '$type', must be one of 1..8");
  }
}
sub htsmsg_message_length {
  # determine message or data length of a htsp message to be deserialised
  my $self = shift;
  my $htsmsg = shift;
  my $template = $self->{template};
  # for database version 3 -> a variable-length integer discarding leading zero bytes
  # -> template = "w" a BER compressed integer, Bit eight (the high bit) is set on each byte except the last
  # -- or --
  # for HTSP protocol and database version 2 -> 4 byte integer "network" big-endian byte-order
  # -> template = "N"
  my $length = unpack("$template", $$htsmsg);
  substr($$htsmsg,0,length(pack("$template", $length)),'');    # remove number of bytes consumed
  return $length;
  # instead of template "w" we can do like this
  # my ($bits, $seven_bit_chunks) = (1,'');    # initalise
  # while ($bits) {
    # the continuation bit = most significant bit, MSB is set to 1, indicating that more bytes follow
    # $bits = unpack("B8", substr($$htsmsg,0,1,''));    # get next byte as a string of 8 bits
    # $seven_bit_chunks .= substr($bits,1,7,'');    # add next 7-bit chunk
  # }
  # return oct('0b'.$seven_bit_chunks);    # convert bits to value
}
1;
# __ end of package htsp_tvh_client __
__END__

=pod

=encoding utf8

=head1 Name

Tvh::Htsp::Client - a Tvheadend HTSP client library written in perl

Refer to L<HTSP|https://docs.tvheadend.org/documentation/development/htsp>

=head1 Version

Version 0.06

=head1 Synopsis

 use feature 'say';
 use JSON::XS;
 use Tvh::Htsp::Client;

 # Establish client connection to HTSP server
 my $htsp = Tvh::Htsp::Client->new( { host => $host, port => $port, debug_info => $debug_info } );
 #   Be sure to use HTSP 'port', defaults to '9982'
 #   'host' defaults to 'localhost'
 #   'debug_info' defaults to 0
 #    setting it to 1 will output all details of client to server communication, which is normally not required
 # Setup
 my $msg = { method => 'hello', htspversion => 43, clientname => 'Tvh::Htsp::Client', clientversion => "v$Tvh::Htsp::Client::VERSION" };
 my $reply = $htsp->htsp_send_recv($msg);
 # Tvheadend HTSP API or JSON API via HTTP Proxy using HTSP 'api' method
 $msg = { method => 'api', path => 'channel/grid', args => { start => 0, limit => 99999, sort => 'number', dir => 'desc' } };
 $reply = $htsp->htsp_send_recv($msg);
 say JSON::XS->new->encode($reply);
 #
 # -- or --
 #
 # Dump epgdb.v3 TVH Electronic Program Guide (EPG) database in json format
 #   we do not need the client connection to the HTSP server and set parameter 'no_client' to 1
 #   database version 3 sligthly deviates from the HTSP protocol, we  set parameter 'epgdb_v3' to 1
 #   database version 2 uses HTSP protocol, no need to set 'epgdb_v3' in this case
 my $htsp = Tvh::Htsp::Client->new( { no_client => 1, epgdb_v3 => 1 } );
 my $epgdb = qx(7zz e -so /var/lib/tvheadend/epgdb.v3 2>/dev/null);    # unzip epgdb.v3 to string
 my $db=[];
 my $i=0;
 while (length $epgdb) {
   my $bd = $htsp->htsmsg_deserialise(\$epgdb);
   push ($db->@*, $bd);
   $i++ if $bd->{id};
 }
 # Save Tvheadend events database to 'epg-dmp.json'
 open my $file_handle, '>', "epg-dmp.json" or die "'epg-dmp.json' Error opening: $!\n";
 say $file_handle JSON::XS->new->encode($db);
 close $file_handle;
 say "Dumped '$i' TVH Events into 'epg-dmp.json'";

=head1 Description

This module implements a Tvheadend HTSP client library written in perl

L<https://docs.tvheadend.org/documentation/development/htsp>

=head1 Methods

=head2 new

C<$htsp = Tvh::Htsp::Client-E<gt>new( $args );>

Constructor; returns a new Tvh::Htsp::Client object

Valid parameters, all optional: see Synopsis

=head2 getChanUuidId

C<$channelids = $htsp-E<gt>getChanUuidId();>

Get all channel uuid and ID in a hash reference

Valid parameters: none

=head2 getChanNamId

C<($chan_name, $chan_id) = $htsp-E<gt>getChanNamId($channel);>

Get channel name and ID

Valid parameter: channel Name or channel ID or channel Number

=head2 htsp_send_recv

C<$reply = $htsp-E<gt>htsp_send_recv($msg);>

send and receive a HTSP message; returns the deserialised server reply in a hash reference

Valid parameter: hash reference with message to send

=head2 htsp_send

C<$size = $htsp-E<gt>htsp_send($msg);>

send a HTSP message; returns the size in bytes of the serialised message sent

Valid parameter: hash reference with message to send

=head2 htsp_recv

C<$reply = $htsp-E<gt>htsp_recv();>

receive a HTSP message; returns the deserialised server reply in a hash reference

Valid parameter: none

=head2 htsmsg_deserialise

C<$reply = $htsp-E<gt>htsmsg_deserialise($htsmsg);>

deserialise a HTSP message; returns the deserialised message in a hash reference

Valid parameter: scalar reference with HTSP message to deserialise

=head2 DESTROY

C<$htsp-E<gt>DESTROY;>

close IO::Socket

=head1 Author

Ulrich Buck, C<< <ulibuck at cpan.org> >>

=head1 License and Copyright

This software is Copyright (c) 2026 by Ulrich Buck.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

This program is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose.

=cut
