package VoiceXML::Client::Item::Form;

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
};

$VERSION = $VoiceXML::Client::Item::VERSION;




sub init {
	my $self = shift;
	my $params = shift;

	
	
	$self->{'grammars'} = {};
	unless (defined $self->{'id'})
	{
		$self->id($self->{'XMLElement'}->attribute('id') || int(rand(999999)) . time());
		
		$self->{'formVar'} = "formVar_" . $self->id();
		my $expr = $self->{'XMLElement'}->attribute('expr');
		my $cond = $self->{'XMLElement'}->attribute('cond');
		
		if ($expr || $cond)
		{
			if ($expr && $cond)
			{
				$self->{'guard'} = "$expr && $cond";
			} else {
				$self->{'guard'} = $expr || $cond;
			}
		} else {
			$self->{'guard'} = $self->{'formVar'};
		}
		
	}
	my $vxmlDoc = $self->getParentVXMLDocument();
	$vxmlDoc->registerForm($self->id(), $self->{'guard'});
	VoiceXML::Client::Item::Util->declareVariable($self,$self->{'formVar'}) if ($self->{'formVar'});
	
	$self->promptCount(0);
	
	
	return 1;
	
}

sub id {
	my $self = shift;
	my $setTo = shift; # opptional
	
	if (defined $setTo)
	{
		$self->{'id'} = $setTo;
	}
	
	return $self->{'id'};
}

sub enterSub {
	my $self = shift;
	
	my $vxmlDoc = $self->getParentVXMLDocument();
	$self->{'assub'} = 1;
	
	$vxmlDoc->pushPositionStack();
	
	$self->reset();
	$self->promptCount(0);
	# $self->enterForm();
}

sub returnSub {
	my $self = shift;
	
	#my $vxmlDoc = $self->getParentVXMLDocument();
	#$vxmlDoc->popPositionStack();
	$self->{'assub'} = 0;
	$self->clearAutoGuard();
}

sub calledAsSub {
	my $self = shift;
	
	return 1 if (exists $self->{'assub'} && $self->{'assub'});
	
	return 0;
}

sub enterForm {
	my $self = shift;
	
	$self->reset();
	$self->promptCount(0);
	$self->setAutoGuard();
}

sub setAutoGuard {
	my $self = shift;
	
	$self->getParentVXMLDocument()->globalVar($self->{'formVar'}, 1);

}

sub clearAutoGuard {
	my $self = shift;
	
	$self->getParentVXMLDocument()->clearGlobalVar($self->{'formVar'});

}


sub reset {
	my $self = shift;
	
	VoiceXML::Client::Util::log_msg("FORM $self->{'id'} reset() called") if ($VoiceXML::Client::Debug > 1);
	
	$self->clearAutoGuard();
	$self->promptCount(0);
	
	$self->SUPER::reset(0);
}

sub nextItem {
	my $self = shift;
	
	VoiceXML::Client::Util::log_msg("Form::nextItem not implemented yet") if ($VoiceXML::Client::Debug);
	
	return 0;
}
	

sub execute {
	my $self = shift;
	my $handle = shift;
	my $optParms = shift;
	
	VoiceXML::Client::Util::log_msg("Entering form " . $self->id()) if ($VoiceXML::Client::Debug);
	
	$self->incrementPromptCount();
	
	if ($self->promptCount() > 10)
	{
		VoiceXML::Client::Util::log_msg("This form (" . $self->{'id'} . ") tried too often... aborting");
		return $VoiceXML::Client::Flow::Directive{'ABORT'};
	}
	
	$self->setAutoGuard();
	
	return $self->executeChildren($handle, $optParms);
	
}

sub incrementPromptCount {
	my $self = shift;
	
	my $pc = $self->promptCount();
	$pc++;
	$self->promptCount($pc);
	
	return $pc;
}


sub promptCount {
	my $self = shift;
	my $setTo = shift;
	
	if (defined $setTo)
	{
		$self->{'promptCount'} = $setTo;
	}
	
	return $self->{'promptCount'};
	
}

sub inputValidAccordingToGrammar {
	my $self = shift;
	my $input = shift || '';
	my $gramID = shift; # optional
	
	if ($gramID)
	{
		return $self->{'grammars'}->{$gramID}->isValidInput($input);
	}
	
	# no gramID... try 'em all
	my $gramCount = 0;
	while (my ($gid, $grammar) = each %{$self->{'grammars'}})
	{
		return 1 if ($grammar->isValidInput($input));
		$gramCount++;
	}
	
	return 0 if ($gramCount); # failed all grammars...
	
	# no grammars set... always good!
	return 1;
}
		

sub registerGrammar {
	my $self = shift;
	my $id = shift;
	my $grammar = shift || return;
	
	$self->{'grammars'}->{$id} = $grammar;
}



sub isaFormItem {
	my $self = shift;
	
	return 1;
}	


1;
