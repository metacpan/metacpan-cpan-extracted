package VoiceXML::Client::DeviceHandle;

use VoiceXML::Client;
use VoiceXML::Client::Util;
use VoiceXML::Client::Vars;

use strict;

# just need to define an interface for device handles... 
# this really only tells you where to look for the API

use vars qw {
		$DeviceDefined
		%InputMode
		%ReadnumGlobals
		$VERSION
	};

$DeviceDefined = 1;
%InputMode = (
		'FIXEDDIGIT'	=> 1,
		'MULTIDIGIT'	=> 2,
	);

$VERSION = $VoiceXML::Client::VERSION;

=head1 VoiceXML::Client::DeviceHandle

=head1 NAME

	VoiceXML::Client::DeviceHandle - Encapsulates the communications device (eg Voice Modem)


=head1 SYNOPSIS

The VoiceXML::Client::DeviceHandle module is meant to serve as an abstract base
class for voice communication devices.  
	
It provides the interface VoiceXML::Client::DeviceHandle::XXX modules are expected
to implement.

=head1 AUTHOR

LICENSE

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



=head2 new [PARAMHREF]

Creates a new instance, calling init() with PARAMHREF if passed.
Returns a new blessed object.

=cut

sub new {
	my $class = shift;
	my $params = shift;
	
	my $self = {};
        
        bless $self, ref $class || $class;
	
	
	$self->{'autostop'} = (defined $params->{'autostop'}) ? $params->{'autostop'} : $VoiceXML::Client::Vars::Defaults{'autostop'};
	
	$self->{'timeout'} = (defined $params->{'timeout'}) ?  $params->{'timeout'} : $VoiceXML::Client::Vars::Defaults{'timeout'};
	
	$self->{'numrepeat'} = (defined $params->{'numrepeat'}) ?  $params->{'numrepeat'} : $VoiceXML::Client::Vars::Defaults{'numrepeat'};
	
	$self->{'device'} = (defined $params->{'device'}) ? $params->{'device'} : $VoiceXML::Client::Vars::Defaults{'device'};
	
	$self->{'inputmode'} = (defined $params->{'inputmode'}) ? $params->{'inputmode'} : $InputMode{'FIXEDDIGIT'};
	
	while (my ($key, $val) = each %{$params})
	{
		$self->{$key} = $val;
	}

	
	$ReadnumGlobals{$$}{'device_obj'} = $self;
	
	
	$ReadnumGlobals{$$}{'inputReceivedCallbacks'} = {};
	
	
	$self->init($params);
		
	
	return $self;
}


=head2 init PARAMHREF

Called by new(). This method is used in derived classes to perform startup initialisation.
Override this method if required.

=cut

sub init {
	my $self = shift;
	my $params = shift;
	
	
	
	return 1;
	
}


=head1 Subclass method stubs

The following methods are in this parent class (but only implemented as stubs) in order to define a
common interface for all VoiceXML::Client::DeviceHandle subclasses.

These methods are actually heavily based on the Modem::Vgetty package methods and the interface should
be considered tentative and expected to change as new devices are added (eg a SIP voice over IP interface
would be nice).

=cut


sub connect {
	my $self = shift;
	my $params = shift;
	
	print STDERR "VoiceXML::Client::DeviceHandle::connect() Call to parent class stub - please implement in subclass.\n"
		if ($VoiceXML::Client::Debug);
	
	return 1;
}


sub disconnect {
	my $self = shift;
	my $params = shift;
	
	print STDERR "VoiceXML::Client::DeviceHandle::disconnect() Call to parent class stub - please implement in subclass.\n"
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
	
	print STDERR "VoiceXML::Client::DeviceHandle::beep($frequency, $length) Call to parent class stub - please implement in subclass.\n";
	
	return 1;
}



=head2 dial DESTINATION

Connects to destination.  Returns defined & true on success.

=cut

sub dial {
	my $self = shift;
	my $destination = shift;
	
	print STDERR "VoiceXML::Client::DeviceHandle::dial($destination) Call to parent class stub - please implement in subclass.\n";
	
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
	
	
	print STDERR "VoiceXML::Client::DeviceHandle::play($playthis) Call to parent class stub - please implement in subclass.\n";
	
	return 1;
}


=head2 record TOFILE

Records input from user to device to file TOFILE.  Returns true on success.

=cut

sub record {
	my $self = shift;
	my $tofile = shift;
	
	
	print STDERR "VoiceXML::Client::DeviceHandle::record($tofile) Call to parent class stub - please implement in subclass.\n";
	
	return 1;
}


=head2 wait TIME

Simply waits for TIME seconds.  Device should accept/queue user input 
during interval.

=cut

sub wait {
	my $self = shift;
	my $time = shift;
	
	
	print STDERR "VoiceXML::Client::DeviceHandle::wait($time) Call to parent class stub - please implement in subclass.\n";
	
	return 1;
}


=head2 waitFor STATE

Waits until STATE is reached/returned by device.  Device should accept/queue user input 
during interval.

=cut

sub waitFor {
	my $self = shift;
	my $state = shift;
	
	print STDERR "VoiceXML::Client::DeviceHandle::waitFor($state) Call to parent class stub - please implement in subclass.\n";
	
	return 1;
}

=head2 stop

Immediately stop any current activity (wait, play, record, etc.).

=cut
sub stop {
	my $self = shift;
	
	
	print STDERR "VoiceXML::Client::DeviceHandle::stop() Call to parent class stub - please implement in subclass.\n";
	
	return 1;
}

=head2 blocking_play PLAYTHIS

play PLAYTHIS and return only when done.

=cut

sub blockingPlay {
	my $self = shift;
	my $playthis = shift;
	my $type = shift;
	
	
	print STDERR "VoiceXML::Client::DeviceHandle::blocking_play($playthis) Call to parent class stub - please implement in subclass.\n";
	
	return 1;
}


=head2 inputMode [MODE]

Returns the current input mode (single- or multi- digit currently supported), optionally setting to 
MODE, if passed - use the %VoiceXML::Client::DeviceHandle::InputMode hash for valid MODE values.

=cut

sub inputMode {
	my $self = shift;
	my $setTo = shift;
	
	if (defined $setTo)
	{
		$self->{'inputmode'} = $setTo;
	}
	
	return $self->{'inputmode'};
}

=head2 readnum PLAYTHIS TIMEOUT [REPEATTIMES]

Plays the PLAYTHIS and then waits for the sequence of the digit input finished. If no are entered within TIMEOUT 
seconds, it re-plays the message again. It returns failure (undefined value) if no digits are entered after the message
has been played REPEATTIMES (defaults to 3) times. 


It returns a string (a sequence of DTMF tones 0-9,A-D and `*') without the final stop key (normally '#'). 


=cut


sub readnum {
	my $self = shift;
	my $playthis = shift;
	my $timeout = shift;
	my $repeatTimes = shift || 3;
	
	
	print STDERR "VoiceXML::Client::DeviceHandle::beep() Call to parent class stub - please implement in subclass.\n";
	
	return 1;
}




=head2 validDataFormats 

Returns an array ref of valid data formats (eg 'rmd', 'wav', 'au') the device will accept.

=cut

sub validDataFormats {
	my $self = shift;
	
	print STDERR "VoiceXML::Client::DeviceHandle::validDataFormats() Call to parent class stub - please implement in subclass.\n";
	
	return undef;
}



sub receiveImage {
	my $self = shift;
	
	print STDERR "VoiceXML::Client::DeviceHandle::receiveImage() Call to parent class stub - please implement in subclass.\n";
	
	return 1;
}


# Not sure what to do with this method... how do you support faxes while abstracting the modem voice device??
sub sendImage {
	my $self = shift;
	my $file = shift;
	
	print STDERR "VoiceXML::Client::DeviceHandle::sendImage() Call to parent class stub - please implement in subclass.\n";
	
	return 1;
}


sub notifyCallbacksOfInputReceived {
	my $input = shift;
	
	while (my ($name, $dets) = each %{$ReadnumGlobals{$$}{'inputReceivedCallbacks'}})
	{
		VoiceXML::Client::Util::log_msg("Notifying $name of input received") if ($VoiceXML::Client::Debug);
		my $obj = $dets->{'object'};
		my $meth = $dets->{'method'};
		
		$obj->$meth($ReadnumGlobals{$$}{'device_obj'}, $input);
	}
	
	return;
}

sub registerInputReceivedCallback {
	my $self = shift;
	my $name = shift || return;
	my $object = shift;
	my $method = shift;
	
	unless ($object && $object->can($method))
	{
		VoiceXML::Client::Util::log_msg("Trying to register $method on $object but object can't do that");
		return;
	}
	
	VoiceXML::Client::Util::log_msg("Registering $method on $object for input received callback") if ($VoiceXML::Client::Debug);
	
	$ReadnumGlobals{$$}{'inputReceivedCallbacks'}->{$name} = {
						'object'	=> $object,
						'method'	=> $method
						};
	return 1;
}

sub deleteInputReceivedCallback {
	my $self = shift;
	my $name = shift || return;
	
	delete $ReadnumGlobals{$$}{'inputReceivedCallbacks'}->{$name} if (exists $ReadnumGlobals{$$}{'inputReceivedCallbacks'}->{$name});
	
	return;
}



sub resetReadnumGlobalNumberCache {
	my $cacheID = shift || return;
	
	$ReadnumGlobals{$cacheID}{'readnum_number'} = '';
	
	return;
}

sub appendPendingInput {
	my $self = shift;
	my $input = shift;
	
	return unless defined ($input);
	
	$ReadnumGlobals{$$}{'readnum_number'} = '' unless (defined $ReadnumGlobals{$$}{'readnum_number'});
	$ReadnumGlobals{$$}{'readnum_number'} .= $input;
	
	return $input;
}

	
sub pendingInputLength {
	my $self = shift;
	
	
	my $readnumid = $$; # So it's safe to have multiple devices...
	
	my $retnum = defined $ReadnumGlobals{$readnumid}{'readnum_number'} ? 
				$ReadnumGlobals{$readnumid}{'readnum_number'} : '';
				
	VoiceXML::Client::Util::log_msg("pendingInputLength() called returning length of '$retnum'") if ($VoiceXML::Client::Debug > 1);
	
	return length($retnum);
}


sub fetchPendingInput {
	my $self = shift;
	
	
	my $readnumid = $$; # So it's safe to have multiple devices...
	
	my $retnum = defined $ReadnumGlobals{$readnumid}{'readnum_number'} ? 
				$ReadnumGlobals{$readnumid}{'readnum_number'} : '';
	
	resetReadnumGlobalNumberCache($readnumid);
	
	return $retnum;
}


1;
