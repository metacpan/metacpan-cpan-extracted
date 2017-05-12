
package VoiceXML::Client::Item::Audio;


use base qw (VoiceXML::Client::Item);
use VoiceXML::Client::Util;
use VoiceXML::Client::Item::Util;

=head1 COPYRIGHT AND LICENSE

	
	Copyright (C) 2007,2008 by Pat Deegan.
	All rights reserved
	http://voicexml.psychogenic.com

This library is released under the terms of the GNU GPL version 3, making it available only for 
free programs ("free" here being used in the sense of the GPL, see http://www.gnu.org for more details). 
Anyone wishing to use this library within a proprietary or otherwise non-GPLed program MUST contact psychogenic.com to 
acquire a distinct license for their application.  This approach encourages the use of free software 
while allowing for proprietary solutions that support further development.


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



use strict;


use vars qw{
		$VERSION
};

$VERSION = $VoiceXML::Client::Item::VERSION;




sub init {
	my $self = shift;
	
	$self->{'src'} = $self->{'XMLElement'}->attribute('src'); 
	$self->{'expr'} =  $self->{'XMLElement'}->attribute('expr'); 
		
	
	return 1;
}


sub execute {
	my $self = shift;
	my $handle = shift;
	my $optParams = shift;
	
	my $fileToPlay;
	if ($self->{'src'})
	{
		$fileToPlay = $self->{'src'};
	} elsif ($self->{'expr'})
	{
		$fileToPlay = VoiceXML::Client::Item::Util->evaluateExpression($self, $self->{'expr'});
		
	} else {
		warn "Audio::execute() called but no src or expr set";
	}
	
	VoiceXML::Client::Util::log_msg("Audio element playing $fileToPlay") if ($VoiceXML::Client::Debug);
	
	my $errorFileToPlay;
	if ($fileToPlay)
	{
		if (-e $fileToPlay && -r $fileToPlay)
		{
				$handle->play($fileToPlay);
		} else {
				VoiceXML::Client::Util::log_msg("Audio element could not find file '$fileToPlay'");
				$errorFileToPlay = $self->getErrorMessageFile();
		} 
	} else {
		VoiceXML::Client::Util::log_msg("Audio element has no file to play set");
		$errorFileToPlay = $self->getErrorMessageFile();
	}
	
	$handle->play($errorFileToPlay) if ($errorFileToPlay);
	
	return $self->executeChildren($handle, $optParams);
}

sub getErrorMessageFile {
	my $self = shift;
	my $params = shift;
	
	return $params->{'errormsgfile'} 
		if (exists $params->{'errormsgfile'} && $params->{'errormsgfile'} && -r $params->{'errormsgfile'});

	VoiceXML::Client::Util::log_msg("Audio element can't locate error message file") if ($VoiceXML::Client::Debug);
	
	return undef;
}

1;
