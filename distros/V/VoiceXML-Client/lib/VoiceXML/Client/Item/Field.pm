package VoiceXML::Client::Item::Field;


use strict;


use base qw (VoiceXML::Client::Item);
use VoiceXML::Client::Util;
use VoiceXML::Client::Item::Prompt;

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




use vars qw{
		$VERSION
		$DefaultNumDigits
};

$VERSION = $VoiceXML::Client::Item::VERSION;

$DefaultNumDigits = 1;




sub init {
	my $self = shift;
	
	unless (defined $self->{'name'})
	{
		$self->{'name'} = $self->{'XMLElement'}->attribute('name') || int(rand(999999)) . time();
		
	}
	
	$self->{'type'} = $self->{'XMLElement'}->attribute('type') || 'digits';
	
	if ($self->{'type'} eq 'digits')
	{
		$self->{'numdigits'}	=  $self->{'XMLElement'}->attribute('numdigits') || $DefaultNumDigits;
		
		if ($self->{'numdigits'} && $self->{'numdigits'} >= 1)
		{
			$self->{'inputmode'} = $VoiceXML::Client::DeviceHandle::InputMode{'FIXEDDIGIT'};
			VoiceXML::Client::Util::log_msg("Setting input mode to FIXED ($self->{'numdigits'}) for field $self->{'name'}")
				if ($VoiceXML::Client::Debug);
		} else {
			$self->{'inputmode'} = $VoiceXML::Client::DeviceHandle::InputMode{'MULTIDIGIT'};
			VoiceXML::Client::Util::log_msg("Setting input mode to MULTIDIGIT for field $self->{'name'}")
				if ($VoiceXML::Client::Debug);
		}
		
	} else {
		$self->{'numdigits'} = '';
		$self->{'inputmode'} = $VoiceXML::Client::DeviceHandle::InputMode{'MULTIDIGIT'};
		
		VoiceXML::Client::Util::log_msg("Defaulting to MULTIDIGIT mode for field $self->{'name'}")
				if ($VoiceXML::Client::Debug);
	}
	
	
	VoiceXML::Client::Item::Util->declareVariable($self, $self->{'name'});
	
	$self->{'noinput'} = [];
	$self->{'nomatch'} = [];
	$self->{'timeswithoutinput'} = 0;
	$self->{'timesnomatchinput'} = 0;
	$self->{'lastinputstate'} = '';
	$self->{'infilledelement'} = 0;
	
	$self->{'currentinputtimeout'} = $VoiceXML::Client::Item::Prompt::DefaultTimeoutSeconds;
	
	return 1;
	
	
}

sub inputReceivedInterrupt {
	my $self = shift;
	my $handle = shift;
	my $input = shift;
	
	$handle->deleteInputReceivedCallback('fieldinput_' . $self->{'name'});

	if ($self->{'infilledelement'})
	{
	
		$self->abortProcessing(0) ;
	} else {
		
		$self->abortProcessing(1) ;
	}
		
	
	return;
}
	
sub execute {
	my $self = shift;
	my $handle = shift;
	my $optParams = shift;
	
	$self->clearValue();
	$handle->registerInputReceivedCallback('fieldinput_' . $self->{'name'}, $self, 'inputReceivedInterrupt');
	
	$handle->inputMode($self->{'inputmode'}, $self->{'numdigits'});
	
	
	
	for (my $i=0; $i < @{$self->{'children'}}; $i++)
	{
		my $aChild = $self->{'children'}->[$i] || next;
		
		my $cType = $aChild->getType();
		
		if ($cType eq 'VoiceXML::Client::Item::NoInput')
		{
			push @{$self->{'noinput'}}, $aChild;
		} elsif ($cType eq 'VoiceXML::Client::Item::NoMatch')
		{
			
			push @{$self->{'nomatch'}}, $aChild;
		}
	}
	
	
	my $fillFound = 0;
	while (my $curChild = $self->getCurrentChild())
	{
		
		my $cType = $curChild->getType();
		if ($cType eq 'VoiceXML::Client::Item::Filled')
		{
			$self->{'infilledelement'} = 1;
		} else {
			$self->{'infilledelement'} = 0;
		}
			
		if ($self->haveUserInput($handle, $optParams))
		{
			# the user has barged in...  fugget about it--this is a barge in... we don't want to do
			# anything except deal with the filled element if present and collect any remaining input 
		
			
			$self->abortProcessing(0); 
			
			VoiceXML::Client::Util::log_msg("Field -- detected user input...") if ($VoiceXML::Client::Debug > 1);
			
			
				
			unless ($self->{'infilledelement'})
			{
				VoiceXML::Client::Util::log_msg("skipping $cType item") if ($VoiceXML::Client::Debug > 1);
				$self->proceedToNextChild();
				next;
			}
			VoiceXML::Client::Util::log_msg("Dealing with the <filled> item") if ($VoiceXML::Client::Debug > 1);
		}
		

		if ($curChild->can('timeoutSeconds'))
		{
			$self->{'currentinputtimeout'} = 
					$curChild->timeoutSeconds() 
						|| $VoiceXML::Client::Item::Prompt::DefaultTimeoutSeconds;
		}		
		
		if ($self->{'infilledelement'})
		{
			# we are in a <filled> element...
			$fillFound = 1;
			
			$self->abortProcessing(0); 
			# we might just be done here... let's see
			
			unless ($self->getUserInput($handle, $optParams))
			{
				return $self->refetchUserInput($handle, $optParams);
			}
				
		} elsif ($cType eq 'VoiceXML::Client::Item::NoInput' || $cType eq 'VoiceXML::Client::Item::NoMatch')
		{
			# skip these...
			$self->proceedToNextChild();
			next;
		}
	
			
		my $rv = $curChild->execute($handle, $optParams) ;
		
		return $rv if ($rv != $VoiceXML::Client::Flow::Directive{'CONTINUE'});
		
		$self->proceedToNextChild();
	}
	
	unless ($fillFound)
	{
		# no filled element... need some input
		$self->abortProcessing(0); 
		unless ($self->getUserInput($handle, $optParams))
		{
			return $self->refetchUserInput($handle, $optParams);
		}
	}
	
	return $VoiceXML::Client::Flow::Directive{'CONTINUE'};
	
}

sub reset {
	my $self = shift;
	my $vxmlDoc =  $self->getParentVXMLDocument();
	$vxmlDoc->clearGlobalVar($self->{'name'});
	$self->SUPER::reset();
}

sub getBestNoInputItem {
	my $self = shift;
	my $handle = shift;
	my $optParams = shift;
	
	
	my $lastCountMatch = 0;

	my $noInputMatch = $self->{'noinput'}->[0];
	my $idx = 1;
	while ($idx < scalar @{$self->{'noinput'}})
	{
		my $niItem = $self->{'noinput'}->[$idx];
		if ($niItem 
			&& $niItem->{'count'} <= $self->{'timeswithoutinput'} 
			&& $niItem->{'count'} > $lastCountMatch)
		{
			$lastCountMatch = $niItem->{'count'};
			$noInputMatch = $niItem;
		}
		
		$idx++;
	}
	
	return $noInputMatch;
}


sub getBestNoMatchItem {
	my $self = shift;
	my $handle = shift;
	my $optParams = shift;
	
	
	my $lastCountMatch = 0;

	my $nomatchMatch = $self->{'nomatch'}->[0];
	my $idx = 1;
	while ($idx < scalar @{$self->{'nomatch'}})
	{
		my $niItem = $self->{'nomatch'}->[$idx];
		if ($niItem 
			&& $niItem->{'count'} <= $self->{'timesnomatchinput'} 
			&& $niItem->{'count'} > $lastCountMatch)
		{
			$lastCountMatch = $niItem->{'count'};
			$nomatchMatch = $niItem;
		}
		
		$idx++;
	}
	
	return $nomatchMatch;
}
		

sub refetchUserInput {
	my $self = shift;
	my $handle = shift;
	my $optParams = shift;


	
	if ($self->{'lastinputstate'} eq 'none')
	{
		if (scalar @{$self->{'noinput'}})
		{
			my $noInputMatch = $self->getBestNoInputItem($handle, $optParams);
		
			if ($noInputMatch)
			{
				return $noInputMatch->execute($handle, $optParams);
			}
		}
	} elsif ($self->{'lastinputstate'} eq 'invalid')
	{
	
		$self->reset();
		my $noMatchInputItem = $self->getBestNoMatchItem();
		
		if ($noMatchInputItem)
		{
			return $noMatchInputItem->execute($handle, $optParams);
		}
	}
			
	
	$self->{'parent'}->reset();
	return $self->{'parent'}->execute($handle, $optParams);
}

sub haveUserInput {
	my $self = shift;
	my $handle = shift || return undef;
	my $optParams = shift;
	
	
	return $handle->pendingInputLength();
}


sub getUserInput {
	my $self = shift;
	my $handle = shift;
	my $optParams = shift;
	
	

	my $number = $handle->readnum(undef, $self->{'currentinputtimeout'}, 1, $self->{'numdigits'});
	if ($VoiceXML::Client::Debug > 1)
	{
		my $gotnum = (defined $number) ? $number : '';
		VoiceXML::Client::Util::log_msg("Field::getUserInput got '$gotnum'  from handle");
	}
	
	if (defined $number && length($number))
	{
		# got some input... 
		$self->{'timeswithoutinput'} = 0;
		
		if (scalar @{$self->{'nomatch'}})
		{
			# we have some nomatch fields... better check if this input is valid
			# according to our grammmars...
			
			my $parentForm = $self->getParentForm();
			
			if ($parentForm->inputValidAccordingToGrammar($number))
			{
				# huzzah!
				$self->value($number);
		
				return 1;
			}
			
			# the input came in, but was invalid and we have nomatch set...
			
			VoiceXML::Client::Util::log_msg("Field user input considered invalid") if ($VoiceXML::Client::Debug);
			$self->{'lastinputstate'} = 'invalid';
			$self->{'timesnomatchinput'}++;
			return 0;
			
		} else {
		
			# no nomatches set... so no checking, just set the value 
			# whatever it may be...
			
			$self->value($number);
			
			VoiceXML::Client::Util::log_msg("Setting user input to '$number'") if ($VoiceXML::Client::Debug);
		
			return 1;
		}
	} 
	
	VoiceXML::Client::Util::log_msg("Field: no user input received") if ($VoiceXML::Client::Debug);
	
	$self->{'timeswithoutinput'}++;
	$self->{'lastinputstate'} = 'none';
	
	return 0;
}

sub value {
	my $self = shift;
	my $setTo = shift;
	
	my $vxmlDoc =  $self->getParentVXMLDocument();
	
	
	
	if (defined $setTo)
	{
		
		$self->{'lastinputstate'} = 'valid';
		
		VoiceXML::Client::Util::log_msg("Field setting variable " . $self->{'name'} . " to $setTo")
			if ($VoiceXML::Client::Debug);
		
		$vxmlDoc->globalVar($self->{'name'}, $setTo);
	}
	
	return $vxmlDoc->globalVar($self->{'name'});
}

sub clearValue {
	my $self = shift;
	
	VoiceXML::Client::Item::Util->resetVariable($self, $self->{'name'});
	
}
		
		

	
	


1;
