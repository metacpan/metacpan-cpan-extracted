package Voicent;

use 5.008006;
use strict;
use warnings;

use LWP::UserAgent; 
use HTTP::Request::Common;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our @EXPORT = qw(
    host
    port
    call_text
    call_audio
    call_status
    call_remove
    call_till_confirm	
);

our %EXPORT_TAGS = ( 'all' => [ @EXPORT ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '1.1';

# change to the host name for your installation
$Voicent::host = "localhost";
$Voicent::port = 8155;

sub _call_now {
    my %params = %{$_[0]};

    my $ua = LWP::UserAgent->new(agent => 'Mozilla/4.0');

    my $url = 'http://' . $Voicent::host . ':' . $Voicent::port . '/ocall/callreqHandler.jsp';
    my $resp = $ua->request(POST $url,
			    Content_Type  => 'application/x-www-form-urlencoded',
			    Content       => [ %params ]
			    );
    
    unless ($resp->is_success) {
	print "Error sending call request to Voicent Gateway";
	return "";
    }

    my $result = $resp->content();
    my $pos = index ($result, '[ReqId=');
    unless ($pos >=0) {
	print "Error getting call request id from Voicent Gateway";
	return "";
    }
    $pos = $pos + 7;
    my $pos2 = index ($result, ']', $pos);
    my $reqId = substr($result, $pos, $pos2 - $pos);

    return $reqId;
}

sub call_text {
    my ($phoneno, $textmsg, $selfdelete) = @_;

    my %params = ();
    $params{'info'} = 'call ' . $phoneno;
    $params{'phoneno'} = $phoneno;
    $params{'firstocc'} = '10';
    $params{'txt'} = $textmsg;
    $params{'selfdelete'} = $selfdelete;

    return _call_now(\%params);
}

sub call_audio {
    my ($phoneno, $audiofile, $selfdelete) = @_;

    my %params = ();
    $params{'info'} = 'call ' . $phoneno;
    $params{'phoneno'} = $phoneno;
    $params{'firstocc'} = '10';
    $params{'audiofile'} = $audiofile;
    $params{'selfdelete'} = $selfdelete;

    return _call_now(\%params);
}

sub call_status {
    my ($reqId) = @_;

    my $url = 'http://' . $Voicent::host . ':' . $Voicent::port . '/ocall/callstatusHandler.jsp';
    $url = $url . '?reqid=' . $reqId;

    my $ua = LWP::UserAgent->new(agent => 'Mozilla/4.0');

    my $resp = $ua->request(GET $url);
    
    unless ($resp->is_success) {
	print "Error sending call request to Voicent Gateway";
	return "";
    }

    my $result = $resp->content();
    
    if ($result =~ m#\Q^made^\E#) { return "Call Made"; }
    if ($result =~ m#\Q^failed^\E#) { return "Call Failed"; }
    print "";
}

sub call_remove {
    my ($reqId) = @_;

    my $url = 'http://' . $Voicent::host . ':' . $Voicent::port . '/ocall/callremoveHandler.jsp';
    $url = $url . '?reqid=' . $reqId;

    my $ua = LWP::UserAgent->new(agent => 'Mozilla/4.0');

    my $resp = $ua->request(GET $url);
    
    unless ($resp->is_success) {
	print "Error sending call request to Voicent Gateway";
	return "";
    }
}

# voc file must reside on the same machine as the gateway
# this function can be achieved using command line interface
#     vcast.exe -startnow -confirmcode [code] -wavfile [wavfile]

sub call_till_confirm {
    my ($vcast, $vocfile, $confirmcode, $wavfile) = @_;

    my %params = ();
    $params{'info'} = 'call till concel';
    $params{'phoneno'} = '0000000';
    $params{'firstocc'} = '10';
    $params{'startexec'} = $vcast;
    $params{'selfdelete'} = '1';
    $params{'cmdline'} = '"' . $vocfile . '" -startnow -confirmcode ' . $confirmcode
	. ' -wavfile "' . $wavfile . '"';

    return _call_now(\%params);
}
    
# samples
# $reqId = call_text(1234567, 'hello, how are you', 0);
# $reqId = call_audio(1234567, 'C:\temp\welcome.wav', 0);
# $status = call_status($reqId);
# call_remove($reqId);
# call_till_confirm('c:\Program Files\Voicent\BroadcastByPhone\bin\vcast.exe', 'c:\temp\tt1.voc', '1234', 'c:\temp\welcome.wav');


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Voicent - Interface for making telephone calls using Voicent Gateway

This is the perl interface module for Voicent Gateway, a VoiceXML 
gateway. You can use this interface module to make telephone calls
from your perl program, provided that the Voicent Gateway is
installed and can be accessed through HTTP. There is a FREE version
of Voicent Gateway program downloadable from:

http://www.voicent.com/download

=head1 SYNOPSIS

  use Voicent;

  call_text   <phone number> <text message> <selfdelete>
  call_audio  <phone number> <audio file> <selfdelete>
  call_status <call reqId>
  call_remove <call reqId>
  call_till_confirm <vcast exe> <call list voc> <confirm code> <wavefile>

=head1 DESCRIPTION

This module contains a collection of functions to the Voicent Gateway. You can
use it to make telephone calls from your perl program.

=head2 call_text

=head3 Synopsis

    call_text <phoneno> <text message> <selfdelete>

=head3 Description

Make a phone call and play the specified text message. The text message is convert to voice by Voicent Gateway's text-to-speech engine.

=head3 Options
 
    <phoneno>      The phone number to call

    <text message> The message for the phone call 

    <selfdelete>   Ask the gateway to automatically delete the call request after the call is made if it is set to '1' 

    The return value is the call request id <reqId>. 

=head3 Example

    call_text('123-4567', 'Hello, how are you doing', 1); 

Make a call to phone number '123-4567' and say 'Hello, how are you doing'. Since the selfdelete bit is set, the call request record in the gateway will be removed automatically after the call.
  
    $reqId = call_text(123-4567, 'Hello, how are you doing', 0);
  
Make a call to phone number '123-4567' and say 'Hello, how are you doing'. Since the selfdelete bit is not set, the call request record in the gateway will not be removed after the call. You can then use call_status to get the call status, or use call_remove to remove the call record.


=head2 call_audio

=head3 Synopsis

    call_audio <phoneno> <audiofile> <selfdelete>

=head3 Description

Make a phone call and play the specified audio message.

=head3 Options

    <phoneno>     The phone number to call
 
    <audiofile>   The audio message for the phone call. The format must be PCM 16bit, 8KHz, mono wave file. The audio file must be on the same host as Voicent Gateway.
 
    <selfdelete>  Ask the gateway to automatically delete the call request after the call is made if it is set to '1' 

    The return value is the call request id <reqId>. 

=head3 Example

    call_audio('123-4567', 'C:\my audios\hello.wav', 1); 

Make a call to phone number '123-4567' and play the hello.wav file. Since the selfdelete bit is set, the call request record in the gateway will be removed automatically after the call.
  
    $reqId = call_audio(123-4567, 'Hello, how are you doing', 0);
  
Make a call to phone number '123-4567' and play the hello.wav file. Since the selfdelete bit is not set, the call request record in the gateway will not be removed after the call. You can then use call_status to get the call status, or use call_remove to remove the call record.


=head2 call_status

=head3 Synopsis

    call_status <reqId> 

=head3 Description

Check the call status of the call with <reqId>. If the call is made, the return value is 'Call Made', or if the call is failed, the return value is 'Call Failed', and for any other status, the return value is ''.

=head3 Example

    $status = call_status('11234035434');

=head2 call_remove

=head3 Synopsis

    call_remove <reqId>

=head3 Description

Remove the call record of the call with <reqId>. If the call is not made yet, it will be removed also. 

=head3 Example

    call_remove('11234035434');


=head2 call_till_confirm

=head3 Synopsis

    call_till_confirm <vcast prog> <vcast doc> <confirmcode> <wavfile>

=head3 Description

Keep calling a list of people until anyone enters the confirmation code. The message is the specified audio file. This is ideal for using it in a phone notification escalation process.

To use this feature, Voicent BroadcastByPhone Professional version has to be installed. This function is similar to the command line interface BroadcastByPhone has. But since the command cannot be invoke over a remote machine, this perl function uses the gateway to schedule an event, which in turn invokes the command on the gateway host.

=head3 Options

    <vcast prog>     The BroadcastByPhone program. It is usually 'C:\Program Files\Voicent\BroadcastByPhone\bin\vcast' on the gateway host.
 
    <vcast doc>     The BroadcastByPhone call list to use.
 
    <confirmcode>   The confirmation code use for the broadcast 

    <wavfile>       The audio file to use for the broadcast 


=head3 Example

    call_till_confirm(
        'C:\Program Files\Voicent\BroadcastByPhone\bin\vcast.exe',
        'C:\My calllist\escalation.voc',
        '911911',
        'C:\My calllist\escalation.wav'); 

This will invoke BroadcastByPhone program on the gateway host and start calling everyone one the call list defined in 'C:\My calllist\escalation.voc'. The audio message played is 'C:\My calllist\escalation.wav'. And as soon as anyone on the list enters the confirmation code '911911', the call will stop automatically. 

=head2 EXPORT

None by default.


=head1 SEE ALSO

Please check online http://www.voicent.com/devnet

=head1 AUTHOR

Andrew Kern, Voicent Communications, E<lt>andrew@voicent.comE<gt>

=head1 COPYRIGHT AND LICENSE

This software is provided AS_IS.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
