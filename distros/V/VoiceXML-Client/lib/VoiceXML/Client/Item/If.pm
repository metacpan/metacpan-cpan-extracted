
package VoiceXML::Client::Item::If;


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

$VERSION = $VoiceXML::Client::Item::VERSION;


	
	
sub init {
	my $self = shift;
	
	my $cond = $self->{'XMLElement'}->attribute('cond');
	
	unless (defined $cond)
	{
		VoiceXML::Client::Util::log_msg("No condition set in IF clause");
		return undef;
	}
	
	$self->{'cond'} = $cond;
	
	return 1;
	
	
}


sub execute {
	my $self = shift;
	my $handle = shift;
	my $optParms = shift;
	
	my $vxmlDoc = $self->getParentVXMLDocument();
	
	$self->reset();
		
	# check if the IF condition is met...
	
	if ($self->evaluateCondition($self->{'cond'}, $vxmlDoc))
	{
		
		
		while (my $curChild = $self->getNextSameLevelChild())
		{
			
			my $rv = $curChild->execute($handle, $optParms);
			
			return $rv if ($rv != $VoiceXML::Client::Flow::Directive{'CONTINUE'});
		}
		
		return $VoiceXML::Client::Flow::Directive{'CONTINUE'};
	}
	
	# if condition not met... if we have any kids
	
	while (my $condChild = $self->getNextConditionChild())
	{
		my $matchFound = 0;
		if (exists $condChild->{'cond'})
		{
			
			if ($self->evaluateCondition($condChild->{'cond'}, $vxmlDoc))
			{
				
				# we've found a good one.
				$matchFound = 1;
			}
		} else {
			
			# it's an else...
			$matchFound = 1;
		}
		
		if ($matchFound)
		{
			# got a good one...
			while (my $sChild = $self->getNextSameLevelChild())
			{
				
				my $rv = $sChild->execute($handle, $optParms);
				return $rv if ($rv != $VoiceXML::Client::Flow::Directive{'CONTINUE'});
				
			}
			
			
			# and we're done.
			return $VoiceXML::Client::Flow::Directive{'CONTINUE'};
		}
	}
	
	#if we get here... nothing matched/there's nothing to do.
	
	return $VoiceXML::Client::Flow::Directive{'CONTINUE'};
	
	
}

sub getNextSameLevelChild {
	my $self = shift;
	
	while (my $curChild = $self->getCurrentChild())
	{
		$self->proceedToNextChild();
		
		my $ctype = $curChild->getType() ;
		
		
		if ($ctype eq 'VoiceXML::Client::Item::Elseif'
				|| $ctype eq 'VoiceXML::Client::Item::Else')
		{
			# party's over...
			return undef;
		}
		
		return $curChild ; 
	}
		
	
	return undef;
}

sub getNextConditionChild {
	my $self = shift;
	
	
	while (my $curChild = $self->getCurrentChild())
	{
		
		$self->proceedToNextChild();
		
	
		my $ctype = $curChild->getType() ;
		return $curChild if ($ctype eq 'VoiceXML::Client::Item::Elseif'
				|| $ctype eq 'VoiceXML::Client::Item::Else');
				
	}
	
	return undef;
}


sub evaluateCondition {
	my $self = shift;
	my $condition = shift || '';
	my $vxmlDoc = shift || $self->getParentVXMLDocument();
	

	return VoiceXML::Client::Item::Util->evaluateCondition($self, $condition, $vxmlDoc);
	
}
	


1;
