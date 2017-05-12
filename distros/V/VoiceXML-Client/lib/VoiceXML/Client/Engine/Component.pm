package VoiceXML::Client::Engine::Component;

use VoiceXML::Client::Util;

use strict;



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


=head2 DESCRIPTION

The VXML::Engine uses a number of components.  These components serve to abstract 
away platform specific details, such as supported voice device hardware, TTS engines
etc.

All components must use the VoiceXML::Client::Engine::Component as a base class (possibly
indirectly, through multi-leveled inheritance).  The VoiceXML::Client::Engine::Component serves
as an abstract base class for all components, thereby assuring the engine that all it's 
components will provide a minimal common interface.

The VoiceXML::Client::Engine::Component class also implements the functionality that allows
components to interact with other components, while using the engine as a mediator - thus
eliminating any component interdependance (see the engineRequest() method); Components only
know about the engine and the engine only guarantees that it will attempt to fullfill the 
request and will not die in the process.

=head2 NOTES

Subclasses of Component may not use the reserved _component_ keyword as the first part
of object hash keys (eg $self->{'_component_blah'}).


=head2 new ENGINEOBJ [PARAMS]

=cut

sub new {
	my $class = shift;
	my $engine = shift;
	my $params = shift;
	
	
	my $self = {};
        
        bless $self, ref $class || $class;
	
	
	VoiceXML::Client::Util::error("Must pass an engine mediator object to VoiceXML::Client::Engine::Component::new()")
		unless ($engine);
	
	$self->{'_component_type'} = ref $class || $class;
	
	$self->{'_component_engine'} = $engine;
	
	$self->init($params);
	
	return $self;
}



sub init {
	my $self = shift;
	my $params = shift;
	
	return 1;
}


=head2 engineRequest TYPE [PARAM1 [PARAM2] [...]]

All components may request actions from the engine, using the engineRequest method.  This method serves to mediate
requests between components. For instance, a document fetcher may request the engine play background music while 
fetching a document, then request the engine stop playing music when done - all without the fetcher knowing anything
about the audio components (Audio::Output and Audio::Device) involved in the activity.

=cut

sub engineRequest {
	my $self = shift;
	my $request = shift;
	
	
	return $self->{'_component_engine'}->componentRequest($self, $request, @_);
}
	

1;
