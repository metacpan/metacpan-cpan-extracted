package VoiceXML::Client::UserAgent;

use VoiceXML::Client::Parser;

use Hash::Util qw(lock_hash);
use LWP::UserAgent;
use HTTP::Cookies;
use VoiceXML::Client::Engine::Component::Interpreter::Perl;


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
		%Directive
};

$VERSION = '1.0.0';

%Directive = (

);
Hash::Util::lock_hash(%Directive);

sub new {
	my $class = shift;
	my $domain = shift || 'localhost';
	my $basepath = shift || '/';
	my $params = shift || {};
	
	my $self = {};
        
        bless $self, ref $class || $class;
	
	$self->{'domain'} = $domain;
	$self->{'basepath'} = $basepath;
	
	if (exists $params->{'agent'})
	{
		$self->{'agent'} = $params->{'agent'};
	} else {
		$self->{'agent'} = "VoiceXML::Client VOCP VoiceBrowser/$VERSION";
	}
	
	if (exists $params->{'protocol'})
	{
		$self->{'protocol'} = $params->{'protocol'};
	} else {
		$self->{'protocol'} = 'http';
	}
	
	if (exists $params->{'runtime'})
	{
		$self->{'runtime'} = $params->{'runtime'};
	} else {
		$self->{'runtime'} = VoiceXML::Client::Engine::Component::Interpreter::Perl->runtime();
	}
	
	if (exists $params->{'errormsgfile'})
	{
		$self->{'errormsgfile'} = $params->{'errormsgfile'};
	} else {
		$self->{'errormsgfile'} = '';
	}
	
	$self->initUA($params);
	
	$self->{'vxmlparser'} = new VoiceXML::Client::Parser || die "Could not create parser??";
	
	return $self;
}

sub initUA {
	my $self = shift;
	my $params = shift;
	
	
	unless (exists $self->{'cookiejar'})
	{
	
		my %cookieParams = (
			);
	
		if ($params->{'cookiefile'})
		{
			$cookieParams{'file'} = $params->{'cookiefile'};
		}
	
		$self->{'cookiejar'} = HTTP::Cookies->new( %cookieParams );
	}
	
	$self->{'ua'} = LWP::UserAgent->new(
				'agent'	=> $self->{'agent'},
				'cookie_jar'	=> $self->{'cookiejar'},
				);
	
	return 1;
}
sub constructFullURL {
	my $self = shift;
	my $url = shift || '' ;
	
	if ($url !~ m|^\w+://|)
	{
		# not full url...
		my $fullURL = $self->{'protocol'} . '://' . $self->{'domain'};
		
		if ($url !~ m|^/|)
		{
			# not full path...
			$fullURL .= $self->{'basepath'};
		}
		
		$fullURL .= $url;
		
		VoiceXML::Client::Util::log_msg("constructFullURL return $fullURL");
		return $fullURL;
	}
	
	# it is full already...
	return $url;
}

sub get {
	my $self = shift;
	my $url = shift;
	
	return $self->{'ua'}->get($self->constructFullURL($url));
}

sub post {
	my $self = shift;
	my $url = shift ;
	my $data = shift || {};
	
	return $self->{'ua'}->get($self->constructFullURL($url), $data);
}

sub runApplication {
	my $self = shift;
	my $url = shift || die "VoiceXML::Client::UserAgent::runApplication MUST pass start URL";
	my $deviceHandle = shift  || die "VoiceXML::Client::UserAgent::runApplication MUST pass device handle";
	
	
	my $itemExecParams = {
				'errormsgfile'	=> $self->errorMessageFile()
	};
	
	my $retVal;
	my $docCount = 0;
	do {
	
		my $response = $self->get($url);
	
		unless ($response->is_success)
		{
			warn "Could not fetch document $url";
			die $response->status_line;
		}
		
		$docCount++;
		
		my $vxmlFileContents = $response->content;
		print STDERR "$vxmlFileContents" if ($VoiceXML::Client::Debug > 2);
		my $vxmlDoc = $self->{'vxmlparser'}->parse($vxmlFileContents, $self->{'runtime'}) || die "Could not parse response from $url";
		
		
		$retVal = $vxmlDoc->execute($deviceHandle, $itemExecParams);
		
		if ($retVal == $VoiceXML::Client::Flow::Directive{'NEXTDOC'})
		{
			$url = $vxmlDoc->nextDocument();
			die "Told to go to next doc, but nextDocument not set" unless ($url);
		}
		
	} while ($retVal == $VoiceXML::Client::Flow::Directive{'NEXTDOC'});
	
	VoiceXML::Client::Util::log_msg("Application completed ($retVal) after $docCount fetches");
	
	return ;
}


sub errorMessageFile {
	my $self = shift;
	my $setTo = shift;
	
	if (defined $setTo && -r $setTo)
	{
		$self->{'errormsgfile'} = $setTo;
	}
	
	return $self->{'errormsgfile'};
	
}
	


	
1;
