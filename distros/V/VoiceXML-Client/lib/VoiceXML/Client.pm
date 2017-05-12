package VoiceXML::Client;



=head1 NAME

VoiceXML::Client - Perl extension for VoiceXML (VXML) clients, including useragent, parser and interpreter.

=head1 SYNOPSIS

	
	#!/usr/bin/perl
	
	use VoiceXML::Client;
	
	use strict;
	
	# basic info for VoiceXML source
	my $sourceSite = 'voicexml.psychogenic.com';
	my $startURL = '/vocp.cgi';
	
	
	# using dummy device here, to get started
	my $telephonyDevice = VoiceXML::Client::Device::Dummy->new();
	$telephonyDevice->connect();
	
	# our workhorse: the user agent
	my $vxmlUserAgent = VoiceXML::Client::UserAgent->new($sourceSite);
	
	# go for it:
	$vxmlUserAgent->runApplication($startURL, $telephonyDevice);
	
	# that's it... runApplication will return when it has hung up the device.
	

=head1 DESCRIPTION

The VoiceXML::Client library allows you to fetch, parse and interpret VoiceXML files.  

It was developed as a supporting component of the (upcoming version of the) VOCP voice messaging system (http://www.vocpsystem.com).

It's role is to:

	- fetch vxml files
	- parse their contents
	- interpret them by executing the instructions therein

It is not (yet) a complete implementation of the VoiceXML specs, but does support a lot of interesting features.  
Have a look at the included exampleBBSBox.vxml file for an idea of what is possible.  
A quick tour of this file will give you a taste of what's available.


=head2 Telephony Interface


As noted above, the user agent's runApplication() method is called with two parameters: 
a URL and a handle to some telephony device.  

While executing the voicexml code, VoiceXML::Client will likely need to do things like 
play audio files, collect user DTMF input and allow callers to leave messages.  The vxml 
page tells VoiceXML::Client what to do, and the telephony interface is used to actually
perform these actions.

Exactly how the device collects user input etc is left as an excercise to the implementor.
The only thing that counts from VoiceXML::Client's perspective is that the handle support
the VoiceXML::Client::DeviceHandle interface.

During testing, you may use VoiceXML::Client::Device::Dummy as the telephony handle.  This
is a simplified implementation whose only effect is to print all calls to stdout and 
request DTMF input from the command line, when required.

As a programmer, the majority of your work will be in replacing the VoiceXML::Client::Device::Dummy device in the code above with
some implementation of the API that actually controls an interesting device.  See the Telephony Interface section on

 
 http://voicexml.psychogenic.com/api.php


for a complete discussion, or have a look at the VoiceXML::Client::Device::Dummy and VoiceXML::Client::DeviceHandle documentation.




=head2 VoiceXML

A complete discussion of the supported VoiceXML can be found at 
 
 http://voicexml.psychogenic.com/voicexml.php

A summary is provided here.  


VXML provides for TUI forms to be "displayed" to users (through recorded prompts), and can accept input that fills fields within the form.

Each user input field is set based on user DTMF input, and other variables can be created and manipulated in the VXML:


     
     <?xml version="1.0" ?>
     <vxml version="2.1">

	<var name="invalidcount" />
		
	<assign name="invalidcount" expr="0" />

	<form id="guestbox">
		<field name="movetosel" type="digits" numdigits="1">
		
			<prompt timeout="5s">
				
				 <audio src="/path/to/vocpmessages/guestbox500.rmd" />
				
				 <audio src="/path/to/vocpmessages/system/guestinstructions.rmd" />
			</prompt>
			
			<filled>

				<if cond="movetosel == 1">
					<goto nextitem="listennext" />
					
				 <elseif cond="movetosel == 2" />
					<goto nextitem="leaveyourown" />
					
				 <else />
					<assign name="invalidcount" expr="invalidcount + 1" />
					<audio src="/path/to/vocpmessages/system/invalidselection.rmd" />
					<reprompt />
				</if>
			</filled>
		</field>
	</form>
     </vxml>
	

Here you can see a lot of the action.  The invalidcount variable is created and set to 0.  The first form encountered is entered, the prompt for the first field (movetosel) contains prompts which are played.  The filled item awaits user input.  Once this is received (or times out), a variable of the same name as the field is initialized with user input.  

Conditionals can check	the value entered by the user, and jump to other forms within the page (or to other pages).  Simple arthmetic can also be performed as demonstrated by the invalidcount counter.

Voice recordings can be made by users through the use of a <record> item:

		<record beep="true" name="/path/to/vocpspool/500-tmp-ns3aUp4kQ.rmd" />
		
You may also use <goto> items to GET another page:
	
		<goto next="vocp.cgi" />
		
and more complex actions may be performed by submitting data collected through a submit element:

		
		<submit next="vocp.cgi" namelist="box msgstartindex nextdirection action step" />

would fetch the page output by the same script but would also pass along the values of each of the variables specified in the namelist.

More information can be found at http://voicexml.psychogenic.com/

=head2 Supported Elements

Currently, the following VoiceXML elements are recognized and supported, at least partially:

	 - assign
	 - audio
	 - block
	 - break
	 - clear
	 - disconnect
	 - else
	 - elseif
	 - field
	 - filled
	 - form
	 - goto
	 - grammar
	 - if
	 - noinput
	 - nomatch
	 - option
	 - prompt
	 - record
	 - reprompt
	 - return
	 - rule
	 - subdialog
	 - submit
	 - var

A description and examples of each will be found in the VoiceXML section of the project site, at

 http://voicexml.psychogenic.com/voicexml.php
 
 

=head2 Interpreter

Variables may be set and manipulated while executing the contents of a voicexml page.  The
Voice Extensible Markup Language specifications are, currently, far from respected in this
regard within VoiceXML::Client.  Instead of using a full ECMAScript interpreter, a simple
Perl interpreter was created that is, to date, sufficient for most of our requirements.

What is available includes, variable creation:

	<var name="invalidcount" />
	<var name="filetoplay" />


and assignment:
		
	<assign name="invalidcount" expr="0" />
	<assign name="filetoplay" expr="'/path/to/a/file.rmd'" />

Note that, unlike numeric values, strings need to be 'quoted'.  Comparison operators may be used in the 
cond attribute of if/elseif elements, and simple arithmetic may be performed in expr attributes:


	<if cond="movetosel == 1">
		<goto nextitem="listennext" />
			
	 <elseif cond="movetosel == 2" />
		<goto nextitem="leaveyourown" />
					
	 <elseif cond="movetosel &gt; 5 />
	 	<assign name="invalidcount" expr="invalidcount + 1" />
		<reprompt />
	 <else />
	 	<submit next="somewhereelse.cgi" namelist="filetoplay movetosel" />
	</if>

Note here that <, >, <= and >= must be HTML encoded.

Variables may also be used in places like <audio> tags, instead of explicitly setting the src you can:

	
	<audio expr="filetoplay" />

Since this is a variable name, it is not 'quoted'... that's why the file played is whatever is set in the
filetoplay variable, rather than a file called 'filetoplay'.

This implementation is far from complete and has a number of limitations (e.g. though expr="invalidcount + 1" 
currently works, changing the order or adding two variables would likely fail) but a number of examples can
be seen within the included exampleBBSBox.vxml file and on http://voicexml.psychogenic.com/

If you stick to these conventions, you're vxml will work now and in the future, when a true 
interpreter is developed for or incorporated within VoiceXML::Client.


=head1 SEE ALSO

Detailed documentation is available on the project site at 

  
 http://voicexml.psychogenic.com/


VoiceXML::Client was created as a supporting component of the second version of the 
VOCP voice messaging system (http://www.vocpsystem.com).

It relies on the capabilities of the pure perl XML::Mini xml parser (http://minixml.psychogenic.com/)


=head1 AUTHOR

Pat Deegan, http://www.psychogenic.com

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


use 5.008008;
use strict;
use warnings;

use strict;

use VoiceXML::Client::DeviceHandle;
use VoiceXML::Client::Device::Dummy;
use VoiceXML::Client::UserAgent;

use vars qw{
		$Debug
};

$Debug = 0;

# get rid of annoying deep recursion warnings from XML::Mini...
$SIG{__WARN__} = sub {
			my $msg = shift;
			print STDERR $msg if ($msg !~ /Deep recursion/);
};

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);


# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.01';




1;
__END__

