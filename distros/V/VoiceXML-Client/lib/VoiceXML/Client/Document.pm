package VoiceXML::Client::Document;



use strict;

use Data::Dumper;
use base qw(VoiceXML::Client::Item);


use vars qw{
		$VERSION
};

$VERSION = $VoiceXML::Client::Item::VERSION;


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


=head2 new 

=cut
sub new {
	my $class = shift;
	my $docname = shift;
	my $runtime = shift;
	
	
	
	my $self = {};
        
        bless $self, ref $class || $class;
	
	
	$self->{'type'} = ref $class || $class;
	$self->{'_runtime'} = $runtime;
	$self->{'_context'} = $runtime->create_context();
	$self->{'docname'} = $docname;
	
	$self->{'forms'} = [];
	$self->{'formindices'} = {};
	
	$self->{'variables'} = {};
	
	$self->{'nextform'} = 0;
	$self->{'nextdocument'} = 0;
	$self->{'currentitem'} = 0;
	
	
	return $self;
}

sub init {
	my $self = shift;
	
	$self->{'items'} = [];
	
	return 1;
}


=head2 addItem ITEM

Appends ITEM to the list of items for the document.  Items may be any VXML::Item::XXX subclass, while
ITEM itself may be a single ITEM object reference or an ARRAY ref of VXML::Item::XXX objects (each will
be appended in order).

Returns the number of appended items.

=cut

sub addItem {
	my $self = shift;
	my $item = shift;
	
	
	my $count = 0;
	if (ref $item eq 'ARRAY')
	{
		foreach my $singleItem (@{$item})
		{
			$count += $self->addItem($singleItem);
		}
	} else {
	
		push @{$self->{'items'}}, $item;
		$count = 1;
	}
	
	return $count;
	
}

sub nextFormId {
	my $self = shift;
	my $setTo = shift; # optional
	
	if (defined $setTo && exists $self->{'formindices'}->{$setTo})
	{
		$self->{'nextform'} = $setTo;
		my $nextFormIdx = $self->getFormItemsIndex($setTo);
		
		$self->{'currentitem'} = $nextFormIdx;
		$self->{'items'}->[$nextFormIdx]->reset();
		
		return $setTo;
		
	}
	
	my $idx = 0;
	if ($self->{'nextform'})
	{
		my $nextFormName = $self->{'nextform'};
		
		if (exists $self->{'formindices'}->{$nextFormName}
			&& ( exists $self->{'forms'}->[$self->{'formindices'}->{$nextFormName}] )
		)
		{
			$idx = $self->{'formindices'}->{$nextFormName};
			$self->{'variables'}->{$self->{'forms'}->[$idx]->{'guard'}} = undef;
		}
	}
	
	for (my $i = $idx; $i < scalar @{$self->{'forms'}}; $i++)
	{
	
		if ($self->{'variables'}->{$self->{'forms'}->[$i]->{'guard'}})
		{
			VoiceXML::Client::Util::log_msg("nextFormId() Skipping form " . $self->{'forms'}->[$i]->{'name'} 
					. ' because guard condition is set') if ($VoiceXML::Client::Debug > 1);
		} else {
			VoiceXML::Client::Util::log_msg("nextFormId() returning form id " . $self->{'forms'}->[$i]->{'name'} )
				if ($VoiceXML::Client::Debug);
			return $self->{'forms'}->[$i]->{'name'} ;
		}
	}
	
	return undef;
}

sub getForm {
	my $self = shift;
	my $id = shift ;
	
	my $idx = $self->getFormItemsIndex($id);
	
	
	return undef unless (defined $idx);

	return $self->{'items'}->[$idx];
	
}

sub getFormItemsIndex {
	my $self = shift;
	my $id = shift ;
	
	return undef unless defined ($id);

	for (my $i=0; $i < scalar @{$self->{'items'}}; $i++)
	{
		my $itm = $self->{'items'}->[$i];
		
		if ($itm->{'type'} eq 'VoiceXML::Client::Item::Form'
				&& $itm->{'id'} eq $id)
		{
			VoiceXML::Client::Util::log_msg("Found form $id att idx $i")
				if ($VoiceXML::Client::Debug > 1);
			
			return $i ;
		}
				
	}
	
	return undef;
}
	


sub getNextForm {
	my $self = shift;
	
	my $id = $self->nextFormId();
	
	
	return $self->getForm($id);
	
}

sub getNextItem {
	my $self = shift;
	
	return $self->getNextForm() if ($self->{'nextform'});
	
	
	$self->{'currentitem'} ||= 0;
	
	my $oldChildSetting = $self->{'currentitem'} ;
	my $i = $oldChildSetting;
	while ($i < scalar @{$self->{'items'}})
	{
	
		$self->{'currentitem'} = $i;
		
		my $cType = $self->{'items'}->[$i]->getType();
		if ($cType ne 'VoiceXML::Client::Item::Form')
		{
			# not a form, just return it in sequence
			return $self->{'items'}->[$i];
		
		} else 
		{
			# it IS a form... handle guard vars...
			my $formName = $self->{'items'}->[$i]->id();
			
			if (exists $self->{'formindices'}->{$formName})
			{
				my $formIdx = $self->{'formindices'}->{$formName};
				
				if (! $self->{'variables'}->{$self->{'forms'}->[$formIdx]->{'guard'}})
				{
					# not visited yet... go for it.
					return $self->{'items'}->[$i];
				}
			}
		}
		
		
		$i++;
		
	}
	
	$self->{'currentitem'} = $oldChildSetting;
	
	return undef;
}

sub currentItemPosition {
	my $self = shift;
	my $setTo = shift; # optional
	
	if (defined $setTo && $setTo =~ m/^\d+$/ && $setTo < scalar @{$self->{'items'}})
	{
		$self->{'currentitem'} = $setTo;
	}
	
	return $self->{'currentitem'};
}

sub proceedToNextItem {
	my $self = shift;
	
	return $self->{'currentitem'}++;
	
}			


sub registerForm {
	my $self = shift;
	my $formName = shift;
	my $guard = shift;
	
	push @{$self->{'forms'}}, {
				'name'	=> $formName,
				'guard'	=> $guard};
				
	$self->{'formindices'}->{$formName} = $#{$self->{'forms'}};
	
				
	$self->registerVariable($formName);
}

sub registerVariable {
	my $self = shift;
	my $varName = shift || return;
	my $val = shift;
	
	if (defined $val)
	{
		$self->{'variables'}->{$varName} = $val;
	} else {
		
		$self->{'variables'}->{$varName}  = undef;
	}
	
}

sub globalVar {
	my $self = shift;
	my $varName = shift || return;
	my $val = shift; #optional
	
	
	if (defined $val)
	{
		$self->{'variables'}->{$varName} = $val;
		
		VoiceXML::Client::Util::log_msg("SETTING $varName to '$val'") if ($VoiceXML::Client::Debug > 1);
	}
	
	$self->{'variables'}->{$varName} = undef unless (exists $self->{'variables'}->{$varName});
		
	
	return $self->{'variables'}->{$varName};
}

sub clearGlobalVar {
	my $self = shift;
	my $varName = shift || return;
	
	if (exists $self->{'variables'}->{$varName})
	{
		$self->{'variables'}->{$varName} = undef;
	}
}
	
sub pushPositionStack {
	my $self  = shift;

	unshift @{$self->{'itempositionstack'}}, $self->{'currentitem'} ;
	
	
}

sub latestPositionInStack {
	my $self  = shift;
	
	
	if (scalar @{$self->{'itempositionstack'}})
	{
		return $self->{'itempositionstack'}->[0];
	}
	
	return undef;
	
}

sub popPositionStack {
	my $self = shift;
	
	
	if (scalar @{$self->{'itempositionstack'}})
	{
		return shift @{$self->{'itempositionstack'}};
	}

	return undef;
}

sub execute {
	my $self = shift;
	my $handle = shift || return undef;
	my $params = shift || {};
	my $itemToExec = shift ||  $self->getNextItem();
	
	unless ($itemToExec)
	{
		warn "No form or other item to execute";
		return undef;
	}
	
	my $retVal = $VoiceXML::Client::Flow::Directive{'CONTINUE'};
	
	do {
		
		$self->{'nextform'} = undef; # make certain we start with a clean slate
		
		$retVal = $itemToExec->execute($handle, $params);
	
		$self->proceedToNextItem() if ($retVal != $VoiceXML::Client::Flow::Directive{'JUMP'});
		$itemToExec = $self->getNextItem();
		
		if ($retVal == $VoiceXML::Client::Flow::Directive{'SUBRETURN'})
		{
			my $latestPosInStack = $self->latestPositionInStack();
			if (defined $latestPosInStack)
			{
				$self->popPositionStack();
				$self->{'currentitem'} = $latestPosInStack;
				$itemToExec = $self->{'items'}->[$latestPosInStack];
				$retVal = $VoiceXML::Client::Flow::Directive{'CONTINUE'};
			}
		}
		
				
		
	} while ($itemToExec &&
			($retVal == $VoiceXML::Client::Flow::Directive{'CONTINUE'}
				||
			$retVal == $VoiceXML::Client::Flow::Directive{'JUMP'}));
	
	
	if ($retVal == $VoiceXML::Client::Flow::Directive{'CONTINUE'})
	{
	
		
		warn "Made it through the entire VXML document but instructed to continue--aborting";
		return $VoiceXML::Client::Flow::Directive{'ABORT'};
	}

	return $retVal if ($retVal == $VoiceXML::Client::Flow::Directive{'ABORT'}
				|| $retVal == $VoiceXML::Client::Flow::Directive{'DONE'});
	
	if ($retVal == $VoiceXML::Client::Flow::Directive{'NEXTDOC'})
	{
		# need to jump somewhere... 
		my $nextDoc = $self->nextDocument();
		warn "Told to go to next doc, but nextDocument not set" unless ($nextDoc);
		
		VoiceXML::Client::Util::log_msg("GOING TO $nextDoc") if ($VoiceXML::Client::Debug);
		
	}
	
	return $retVal;
	
}
		
sub nextDocument {
	my $self = shift;
	my $setTo = shift; # optional
	
	if (defined $setTo)
	{
		$self->{'nextdocument'} = $setTo;
	}
	
	return 	$self->{'nextdocument'};
}
	

sub isaVXMLDocument {
	my $self = shift;
	
	return 1;
}

1;
