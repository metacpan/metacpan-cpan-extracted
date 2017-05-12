
package VoiceXML::Client::Item::Prompt;


use base qw (VoiceXML::Client::Item);
use VoiceXML::Client::Util;


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
		$DefaultTimeoutSeconds
};

$VERSION = $VoiceXML::Client::Item::VERSION;

$DefaultTimeoutSeconds = 7;

sub init {
	my $self = shift;
	
	my $timeout = $self->{'XMLElement'}->attribute('timeout') || $DefaultTimeoutSeconds;
	
	if ($timeout =~ m/^\s*(\d+)(\w+)/)
	{
		my $timeVal = $1;
		my $timeUnit = $2;
		if ($timeUnit eq 's')
		{
			$timeout = $1;
		}  elsif ($timeUnit eq 'ms')
		{
			$timeout = int($timeVal / 1000);
			
		} else {
			VoiceXML::Client::Util::log_msg("Invalid prompt timeout time unit $timeUnit -- defaulting to $DefaultTimeoutSeconds seconds");
			$timeout = $DefaultTimeoutSeconds;
		}
		
		if ($timeout < 1)
		{
			VoiceXML::Client::Util::log_msg("Timeout for prompt too small ($timeout) -- defaulting to 1s");
			$timeout = 1;
		}
	}
	
	$self->{'timeoutseconds'} = $timeout;

	
	return 1; 
	
}

sub timeoutSeconds {
	my $self = shift;
	my $setTo = shift;
	
	if (defined $setTo && $setTo =~ m/^\d+$/)
	{
		$self->{'timeoutseconds'} = $setTo;
	}
	
	return $self->{'timeoutseconds'};
}

1;
