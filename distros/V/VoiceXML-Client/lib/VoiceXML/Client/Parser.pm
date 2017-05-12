package VoiceXML::Client::Parser;

use XML::Mini::Document;
use VoiceXML::Client::Item::Factory;
use VoiceXML::Client::Document;

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

=head2 new [FILE]

Creates a new instance


=cut

sub new {
	my $class = shift;
	my $file = shift;
	
	my $self = {};
        
        bless $self, ref $class || $class;
	
	$self->parse($file) if ($file);
		
		
	return $self;
}


=head2 parse FILE

Parses VXML file FILE and returns the VoiceXML::Client::Document object.

=cut

sub parse {
	my $self = shift;
	my $fileOrString = shift || die "VoiceXML::Client::Parser::parse MUST pass string or file";
	my $runtime = shift || die "VoiceXML::Client::Parser::parse MUST pass runtime";
	
	$self->{'_XMLDoc'} = XML::Mini::Document->new();
	$self->{'vxml'} = []; # make sure we're nice and empty
	
	my $numChildrenFound;
	if ($fileOrString =~ m/\n/ || length($fileOrString) > 250)
	{
		# it is VXML content?
		# TODO: Need a better test...
		$numChildrenFound = $self->{'_XMLDoc'}->fromString($fileOrString);
		
		VoiceXML::Client::Util::error("VoiceXML::Client::Parser::parse() No xml children found in string ")
			unless($numChildrenFound);
	} else {
		
		VoiceXML::Client::Util::error("VoiceXML::Client::Parser::parse() Must pass a filename or contents")
			unless ($fileOrString);
	
		VoiceXML::Client::Util::error("VoiceXML::Client::Parser::parse() Can't find file '$fileOrString'")
			unless(-e $fileOrString);
	
		VoiceXML::Client::Util::error("VoiceXML::Client::Parser::parse() Can't read file '$fileOrString'")
			unless(-r $fileOrString);
	
		$numChildrenFound = $self->{'_XMLDoc'}->fromFile($fileOrString) if ($fileOrString);
	
		VoiceXML::Client::Util::error("VoiceXML::Client::Parser::parse() No xml children found in  $fileOrString")
			unless($numChildrenFound);
	}
	
	#print  $self->{'_XMLDoc'}->toString(); exit(0);
	
		
	$self->{'_XMLRoot'} = $self->{'_XMLDoc'}->getRoot();
	
	$self->{'itemFactory'} = VoiceXML::Client::Item::Factory->new();
	
	
	my $vxmlElement = $self->{'_XMLRoot'}->getElement('vxml') 
				|| VoiceXML::Client::Util::error("VoiceXML::Client::Parser::parse() no vxml element found in document.");
	
	my $vxmlChildren = $vxmlElement->getAllChildren();
	my $numChildren = scalar(@{$vxmlChildren});
	
	VoiceXML::Client::Util::error("VoiceXML::Client::Parser::parse() no form elements found in vxml element.")
		unless ($numChildren);
		
	
	my $docname = $fileOrString;
	$docname =~ s|^.*/||;
	
	$self->{'VXMLDoc'} = VoiceXML::Client::Document->new($docname, $runtime);
	
	for(my $i=0; $i < $numChildren; $i++)
	{
		my $name = $vxmlChildren->[$i]->name() || VoiceXML::Client::Util::error("No name for child $i in VoiceXML::Client::Parser::parse()");
		$self->{'vxml'}->[$i] = $self->{'itemFactory'}->newItem($name, $vxmlChildren->[$i], $self->{'VXMLDoc'});
	
	}
	
	$self->{'VXMLDoc'}->addItem($self->{'vxml'});
	
	return $self->{'VXMLDoc'};
}

1;
