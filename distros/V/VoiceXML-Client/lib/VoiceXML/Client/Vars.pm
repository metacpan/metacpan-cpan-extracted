package VoiceXML::Client::DeviceHandle;

use VoiceXML::Client::Util;

use strict;

# just need to define an interface for device handles... 
# this really only tells you where to look for the API

use vars qw {
		%Defaults
		$VERSION
	};

$VERSION = '1.0.0';


=head1 VoiceXML::Client::Vars

=head1 NAME

	VoiceXML::Client::Vars - A few commonly used variables and defaults


=head1 SYNOPSIS

=head1 AUTHOR

LICENSE

    VoiceXML::Client::DeviceHandle module, device handle api based on the VOCP voice messaging system package
    VOCP::Device.
    
    Copyright (C) 2008 Patrick Deegan
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

			
%Defaults = (
		'timeout'	=> 6,
		'numrepeat'	=> 3,
		'device'	=> 'DIALUP_LINE',
		'tempdir'	=> '/tmp',
		'autostop'	=> 1,
	);
