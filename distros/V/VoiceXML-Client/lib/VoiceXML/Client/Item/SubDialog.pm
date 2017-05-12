
package VoiceXML::Client::Item::SubDialog;


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

$VERSION = '1.02';




sub init {
	my $self = shift;
	
	my $src = $self->{'XMLElement'}->attribute('src');
	
	unless ( (defined $src) && length($src))
	{
		VoiceXML::Client::Util::log_msg("subdialog item must have 'src' set.");
		return undef;
	}
	
	$self->{'src'} = $src;
	
	my $cond = $self->{'XMLElement'}->attribute('cond');
	if (defined $cond && length($cond))
	{
		$self->{'cond'} = $cond;
	}
	
	
	return 1;
	
	
}

sub execute {
	my $self = shift;
	my $handle = shift;
	my $optParams = shift;
	
	
	my $vxmlDoc = $self->getParentVXMLDocument();
	
	if (exists $self->{'cond'})
	{
		return $VoiceXML::Client::Flow::Directive{'CONTINUE'}
			unless ($self->evaluateCondition($self->{'cond'}, $vxmlDoc));
	}
	
	
	my $src = $self->{'src'};
	
	my $formID;
	if ($src =~ m/^#(.+)/)
	{
		$formID = $1;
	} else {
		VoiceXML::Client::Util::log_msg("Subdialog::execute() can only handle #internal src for now");
		return $VoiceXML::Client::Flow::Directive{'CONTINUE'};
	}
	
	my $form = $vxmlDoc->getForm($formID);
	
	if (! $form )
	{
		
		VoiceXML::Client::Util::log_msg("Subdialog::execute() can not find form $formID in document");
		return $VoiceXML::Client::Flow::Directive{'CONTINUE'};
	}
	
	if ($self->{'parent'})
	{
		$self->{'parent'}->proceedToNextChild();
	}
	
	VoiceXML::Client::Util::log_msg("Subdialog jumping to form $formID") if ($VoiceXML::Client::Debug);
	
	my $parentForm = $self->getParentForm();
	$parentForm->clearAutoGuard();
	
	$form->enterSub();
	$vxmlDoc->nextFormId($formID);
	
	return $VoiceXML::Client::Flow::Directive{'JUMP'};
	
	
}


sub evaluateCondition {
	my $self = shift;
	my $condition = shift || '';
	my $vxmlDoc = shift || $self->getParentVXMLDocument();
	

	return VoiceXML::Client::Item::Util->evaluateCondition($self, $condition, $vxmlDoc);
	
}
	



1;
