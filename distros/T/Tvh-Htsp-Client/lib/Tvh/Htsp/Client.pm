package Tvh::Htsp::Client;
# Tvheadend HTSP client library written in perl
# https://docs.tvheadend.org/documentation/development/htsp
use strict;
use warnings;
use v5.12;
use feature 'say';
use feature 'state';
use namespace::autoclean;
use IO::Socket qw(AF_INET SOCK_STREAM);
use LooksLike;
use List::Util qw(min max);
our $VERSION     = '0.03';    # set the version for version checking
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
    ) || die "Can't open socket: $IO::Socket::errstr";
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
  # Get channel name and ID
  my $self = shift;
  my $channel = shift;
  my ($chan_name, $chan_id);
  if (LooksLike::integer($channel)) {
    $chan_id = $channel;
    # get channel name
    my $reply = $self->htsp_send_recv({'method' => 'getChannel', 'channelId' => $channel});
    if ($reply->{'channelName'} and $reply->{'channelId'} eq "$channel") {
      $chan_name = $reply->{'channelName'};
    }
    else {die "Error: channelId '$channel' not found -- ".join(', ', map {"'$_ => $reply->{$_}'"} (sort keys $reply->%*))}
  }
  else {
    # Enable async to find channel ID from channel name
    $self->htsp_send({'method' => 'enableAsyncMetadata'});
    # Process messages
    my $chan_nam_id = {};
    while (1) {
      my $reply = $self->htsp_recv();
      if ($reply->{'method'}) {
        if ($reply->{'method'} eq 'channelAdd') {
          $chan_nam_id->{$reply->{'channelName'}} = $reply->{'channelId'};
        }
        elsif ($reply->{'method'} eq 'initialSyncCompleted') {
          last;
        }
      }
    }
    if ($chan_nam_id->{$channel}) {
      # found channel name
      $chan_name = $channel;
      $chan_id = $chan_nam_id->{$channel};
    }
    else {
      # channel name not found
      my $chan_nam_sorted = join(', ', map {"'$_'"} (sort keys $chan_nam_id->%*));
      die ("Error: channel name '$channel' not found in $chan_nam_sorted");
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
  $self->{msg} = $msg;
  my $htspmsg = $self->htsmsg_serialise($msg);    # serialise
  say STDERR $htspmsg if $self->{debug_info};
  say "Sending '$msg->{'method'}'" if $self->{debug_info};
  my $size = $self->{client}->send($htspmsg);
  say "Sent data of length $size" if $self->{debug_info};
  $self->htsmsg_deserialise(\$htspmsg) if $self->{debug_info};    # deserialise
  return $size;
}
sub htsp_recv {
  # receive HTSP message
  my $self = shift;
  my ($buffer, $length) = ('', 0);
  state $rest = '';
  state $i = 0;
  $buffer = $rest;    # den Rest vom vorigen Aufruf übernehmen
  $length = unpack("N",substr($buffer,0,4,'')) if ($buffer);    # Total length of message = 4 byte integer "network" big-endian byte-order
  while (not $buffer) {
    # Anfang der Nachricht sowie deren Länge ermitteln
    $self->{client}->recv($buffer, 4096) // die "Error from socket: $IO::Socket::errstr";    # Bytes vom HTSP Server abrufen
    die "Error: received '$buffer' of length ".length($buffer) unless $buffer;
    say "Received data of length ".length($buffer) if $self->{debug_info};
    say STDERR $buffer if $self->{debug_info};
    while ($length == 0 and $buffer) {
      # enableAsyncMetadata schickt zuerst ein Null-Byte, das müssen wir los werden
      $length = unpack("N",substr($buffer,0,4,''));    # Total length of message = 4 byte integer "network" big-endian byte-order
      say "$i length -- $length" if $self->{debug_info};
    }
    return({ response => 0 }) if ($length == 0 and not $buffer and $self->{msg}->{method} ne "enableAsyncMetadata");
  }
  if ($length > 10000000 and $self->{debug_info}) {
    # eine vermutlich nicht korrekte Überlänge, weil die Bytes nicht korrekt interpretiert werden
    say STDERR $buffer;
    die ("Error: message length '$length' > 10000000, not realistic");
  }
  while ($length > length($buffer)) {
    # die Länge verlangt nach mehr Bytes
    say '$length > length($buffer)' if $self->{debug_info};
    $self->{client}->recv(my $buffer0, min($length-length($buffer),4096)) // die "Error from socket: $IO::Socket::errstr";    # Bytes vom HTPS Server abrufen
    die "Error: received  '$buffer0' of length ".length($buffer0) unless $buffer0;
    say "Received data of length ".length($buffer0) if $self->{debug_info};
    say STDERR $buffer0 if $self->{debug_info};
    $buffer .= $buffer0;    # erhaltene Bytes der Antwort anfügen
  }
  if ($length <= length($buffer)) {
    # die Antwort enthält zusätzliche Bytes der nachfolgenden Nachricht
    say '$length <= length($buffer)' if $self->{debug_info};
    $rest = $buffer;    # Antwort auf '$rest' übertragen
    $buffer = substr($rest,0,$length,'');    # Antwort '$buffer' auf $length kürzen, den Rest auf '$rest' behalten für den nachfolgenden Aufruf von 'htsp_recv'
  }
  say "$i resp -- ".length($buffer) if $self->{debug_info};
  # exit if $i == 15;
  $i++;
  my $htspmsg = pack("N",$length).$buffer;    # die 4 Bytes mit der Länge der Nachricht vorne wieder anhängen
  return $self->htsmsg_deserialise(\$htspmsg);    # Nachricht entpacken und zurückgeben
}
sub htsmsg_serialise {
  # serialise a HTSP message
  my $self = shift;
  my $msg = shift;
  my $sub_message = shift // 0;
  my $htspmsg = '';
  my ($ishash, @keys, @vals);
  if (ref $msg eq "HASH") {
    $ishash = 1;
    @keys = keys $msg->%*;
    @vals = values $msg->%*;
  }
  elsif (ref $msg eq "ARRAY") {
    $ishash = 0;
    @keys = keys $msg->@*;
    @vals = values $msg->@*;
  }
  else {
    die ("Error: message must be a reference of type of 'HASH' or 'ARRAY', not '".ref($msg)."'");
  }
  for my $key (@keys) {
    my $val = shift @vals;
    # say " $key, $val";
    if (ref $val eq "HASH") {
      # Map = 1 = Sub message of type map
      my $type = pack("C",1);    # 1 byte integer
      my $namelength = $ishash ? pack("C",length($key)) : chr(0);    # 1 byte integer
      my $name = $ishash ? $key : '';   # string
      my $data = $self->htsmsg_serialise($val,1);
      my $datalength = pack("N",length($data));    # 4 byte integer "network" big-endian byte-order
      $htspmsg .= $type.$namelength.$datalength.$name.$data;
    }
    elsif (ref $val eq "ARRAY") {
      # List = 5 = Sub message of type list
      my $type = pack("C",5);    # 1 byte integer
      my $namelength = $ishash ? pack("C",length($key)) : chr(0);    # 1 byte integer
      my $name = $ishash ? $key : '';   # string
      my $data = $self->htsmsg_serialise($val,1);
      my $datalength = pack("N",length($data));    # 4 byte integer "network" big-endian byte-order
      $htspmsg .= $type.$namelength.$datalength.$name.$data;
    }
    elsif (LooksLike::integer($val)) {
      # S64 = 2 = Signed 64bit integer
      my $type = pack("C",2);    # 1 byte integer
      my $namelength = $ishash ? pack("C",length($key)) : chr(0);    # 1 byte integer
      my $name = $ishash ? $key : '';   # string
      my $data = pack("q<",$val);    #  64 bit = 8 byte signed integer little-endian byte-order -> q = signed quad (64-bit) value
      # Integers are encoded using a very simple variable length encoding. All leading bytes that are 0 is discarded.
      $data =~ s/\0{1,7}$//;    # 'NUL' Bytes am Ende wegnehmen, ein erstes behalten
      my $datalength = pack("N",length($data));    # 4 byte integer "network" big-endian byte-order
      $htspmsg .= $type.$namelength.$datalength.$name.$data;
    }
    elsif (LooksLike::numeric($val)) {
      # Dbl = 6 = Double precision floating point
      my $type = pack("C",6);    # 1 byte integer
      my $namelength = $ishash ? pack("C",length($key)) : chr(0);    # 1 byte integer
      my $name = $ishash ? $key : '';   # string
      my $data = pack("d",$val);    #  d = A double-precision float in native format
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
  return $sub_message ? $htspmsg : pack("N",length($htspmsg)).$htspmsg;
}
sub htsmsg_deserialise {
  # deserialise a HTSP message
  # https://docs.tvheadend.org/documentation/development/htsp/htsmsg-binary-format
  my $self = shift;
  my $htsmsg = shift;    # Referenz auf die zu de serialisierende message
  state $i=0;
  my $bd={};
  $i++;
  # Root body
  # Length of Root body = 4 byte integer = Total length of message (not including this length field itself)
  my $length = $self->htsmsg_message_length($htsmsg);    # Total length of message
  say "$i -- $length" if $self->{debug_info};
  my $body = substr($$htsmsg,0,$length,'');    # Body = HTSMSG-Field * N = Fields in the root body
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
  state $level="  ";
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
    say "$level$type $namelength $datalength '$name'" if $self->{debug_info};
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
      $level.="  ";
      $self->htsmsg_field_deserialise (\$data, $ref) ;
      substr($level,-2,2,'');
    }
  }
  elsif ($type == 2) {
    # S64 = 2 = Signed 64bit integer
    # Integers are encoded using a very simple variable length encoding. All leading bytes that are 0 is discarded.
    while (length($data) < 8) {$data .= chr(0);}    # mit "NUL" Bytes auffüllen
    $data = unpack("q<",$data);    # 64 bit = 8 byte signed integer little-endian byte-order -> q = signed quad (64-bit) value
    if (ref $bd eq "HASH") {
      $bd->{"$name"} = $data;
    }
    elsif (ref $bd eq "ARRAY") {
      push($bd->@*, $data);
    }
    say "$level$type $namelength $datalength '$name' '$data'" if $self->{debug_info};
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
    say "$level$type $namelength $datalength '$name' '$data'" if $self->{debug_info};
  }
  elsif ($type == 4) {
    # Bin = 4 = Binary blob
    if (ref $bd eq "HASH") {
      $bd->{"$name"} = $data;
    }
    elsif (ref $bd eq "ARRAY") {
      push($bd->@*, $data);
    }
    say "$level$type $namelength $datalength '$name' '$data'" if $self->{debug_info};
  }
  elsif ($type == 5) {
    # List = 5 = Sub message of type list
    say "$level$type $namelength $datalength '$name'" if $self->{debug_info};
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
      $level.="  ";
      $self->htsmsg_field_deserialise(\$data, $ref);
      substr($level,-2,2,'');
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
    say "$level$type $namelength $datalength '$name' '$data'" if $self->{debug_info};
  }
  elsif ($type == 8) {
    # UUID = 8 = 64 bit UUID in binary format
    $data = unpack("H*",$data);    #  16 byte = 128 bit binary number -> H = hex string (high nybble first)
    if (ref $bd eq "HASH") {
      $bd->{"$name"} = $data;
    }
    elsif (ref $bd eq "ARRAY") {
      push($bd->@*, $data);
    }
    say "$level$type $namelength $datalength '$name' '$data'" if $self->{debug_info};
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
    say "$level$type $namelength $datalength '$name' '$data'" if $self->{debug_info};
  }
}
sub htsmsg_message_length {
  # determine message or data length of a htsp message to be desirialised
  my $self = shift;
  my $bytes = shift;
  my $template = $self->{template};
  # database version 3 -> a variable-length integer discarding leading zero bytes
  # -> template = "w" a BER compressed integer, Bit eight (the high bit) is set on each byte except the last
  # -- or --
  # HTSP protocol or database version 2 -> 4 byte integer "network" big-endian byte-order
  # -> template = "N"
  my $length = unpack("$template", $$bytes);
  substr($$bytes,0,length(pack("$template", $length)),'');    # remove number of bytes consumed
  return $length;
  # instead of template "w" we can do like this
  # my ($bits, $seven_bit_chunks) = (1,'');    # initalise
  # while ($bits) {
    # the continuation bit = most significant bit, MSB is set to 1, indicating that more bytes follow
    # $bits = unpack("B8", substr($$bytes,0,1,''));    # get next byte as a string of 8 bits
    # $seven_bit_chunks .= substr($bits,1,7,'');    # add next 7-bit chunk
  # }
  # return oct('0b'.$seven_bit_chunks);    # convert bits to value
}
1;
# __end of package htsp_client__
__END__

=pod

=encoding utf8

=head1 Name

Tvh::Htsp::Client - a Tvheadend HTSP client library written in perl

Refer to L<HTSP|https://docs.tvheadend.org/documentation/development/htsp>

=head1 Version

Version 0.03

=head1 Synopsis

 use feature 'say';
 use JSON::XS;
 use Tvh::Htsp::Client;

 my $htsp = Tvh::Htsp::Client->new( { host => $host, port => $port, debug_info => $debug_info } );
 # Be sure to use HTSP port, defaults to '9982'
 # host defaults to 'localhost'
 # Setup
 my $msg = { 'method' => 'hello', 'htspversion' => 43, 'clientname' => "$creator", 'clientversion' => "v$Tvh::Htsp::Client::VERSION" };
 my $reply = $htsp->htsp_send_recv($msg);
 # Tvheadend HTSP API or JSON API via HTTP Proxy using HTSP 'api' method
 $msg = { method => 'api', path => 'channel/grid', args => { start => 0, limit => 99999, sort => 'number', dir => 'desc' } };
 $reply = $htsp->htsp_send_recv($msg);
 say JSON::XS->new->encode($reply);
 #
 # -- or --
 #
 # Dump epgdb.v3 TVH Electronic Program Guide (EPG) database in json format
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

Valid parameter: channel name or channel ID

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

This software is Copyright (c) 2025 by Ulrich Buck.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
