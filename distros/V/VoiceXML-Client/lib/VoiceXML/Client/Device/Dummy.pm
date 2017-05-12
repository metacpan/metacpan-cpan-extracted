package VoiceXML::Client::Device::Dummy;


use strict;

use base qw(VoiceXML::Client::DeviceHandle);
	

=head1 VoiceXML::Client::Device::Dummy

=head1 NAME

	VoiceXML::Client::Device::Dummy -- a minimally functional implementation the DeviceHandle interface 




=head1 COPYRIGHT AND LICENSE


    VoiceXML::Client::DeviceHandle module, device handle api based on the VOCP voice messaging system package
    VOCP::Device.
    
    Copyright (C) 2002,2008 Patrick Deegan
    All rights reserved


This file is part of VoiceXML::Client.
 
    VoiceXML::Client is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    VoiceXML::Client is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with VoiceXML::Client.  If not, see <http://www.gnu.org/licenses/>.




=cut



sub connect {
	my $self = shift;
	my $params = shift;
	
	print "VoiceXML::Client::Device::Dummy::connect() called\n"
		if ($VoiceXML::Client::Debug);
	
	return 1;
}


sub disconnect {
	my $self = shift;
	my $params = shift;
	
	print "VoiceXML::Client::Device::Dummy::disconnect()\n"
		if ($VoiceXML::Client::Debug);
	
	return 1;
}



=head2 beep FREQUENCY LENGTH

Sends a beep through the chosen device using given frequency (HZ) and length (in miliseconds).  Returns a defined
and true value on success.

=cut

sub beep {
	my $self = shift;
	my $frequency = shift;
	my $length = shift;
	
	print "VoiceXML::Client::Device::Dummy::beep($frequency, $length)\n";
	
	return 1;
}



=head2 dial DESTINATION

Connects to destination.  Returns defined & true on success.

=cut

sub dial {
	my $self = shift;
	my $destination = shift;
	
	print "dialing ($destination)\n";
	
	return 1;
}


=head2 play PLAYPARAM

plays a sound (file, text-to-speech, whatever is appropriate) base on PLAYPARAM.  May or may not block during
play depending on device implementation.  Returns true on success.

=cut

sub play {
	my $self = shift;
	my $playthis = shift;
	my $type = shift;
	
	
	print "Playing ($playthis)\n";
	
	return 1;
}


=head2 record TOFILE

Records input from user to device to file TOFILE.  Returns true on success.

=cut

sub record {
	my $self = shift;
	my $tofile = shift;
	
	
	print "Recording ($tofile) \n";
	
	return 1;
}


=head2 wait TIME

Simply waits for TIME seconds.  Device should accept/queue user input 
during interval.

=cut

sub wait {
	my $self = shift;
	my $time = shift;
	
	
	print "Waiting ($time)\n";
	
	return 1;
}


=head2 waitFor STATE

Waits until STATE is reached/returned by device.  Device should accept/queue user input 
during interval.

=cut

sub waitFor {
	my $self = shift;
	my $state = shift;
	
	print "WaitFor($state)\n";
	
	return 1;
}

=head2 stop

Immediately stop any current activity (wait, play, record, etc.).

=cut
sub stop {
	my $self = shift;
	
	
	print "Stop()\n";
	
	return 1;
}

=head2 blocking_play PLAYTHIS

play PLAYTHIS and return only when done.

=cut

sub blockingPlay {
	my $self = shift;
	my $playthis = shift;
	my $type = shift;
	
	
	print "Playing ($playthis)... blocked\n";
	
	return 1;
}




=head2 readnum PLAYTHIS TIMEOUT [REPEATTIMES]

Plays the PLAYTHIS and then waits for the sequence of the digit input finished. If none are entered within TIMEOUT 
seconds, it re-plays the message again. It returns failure (undefined value) if no digits are entered after the message
has been played REPEATTIMES (defaults to 3) times. 


It returns a string (a sequence of DTMF tones 0-9,A-D and `*') without the final stop key (normally '#'). 


=cut


sub readnum {
	my $self = shift;
	my $playthis = shift;
	my $timeout = shift;
	my $repeatTimes = shift || 3;
	
	
	print STDOUT "\nEnter DTMF Selection ([0-9]+<ENTER>):";
        my $num = <STDIN>;
        chomp($num);
        $num =~ s/[^\d\*]+//g;


        return $num;

}


=head2 validDataFormats 

Returns an array ref of valid data formats (eg 'rmd', 'wav', 'au') the device will accept.

=cut

sub validDataFormats {
	my $self = shift;
	
	print "ValidDataFormats() queried\n";
	
	return ['rmd', 'wav', 'mp3'];
}



sub receiveImage {
	my $self = shift;
	
	print "ReceiveImage()\n";
	
	return 1;
}


# Not sure what to do with this method... how do you support faxes while abstracting the modem voice device??
sub sendImage {
	my $self = shift;
	my $file = shift;
	
	print "SendImage()\n";
	
	return 1;
}



1;
