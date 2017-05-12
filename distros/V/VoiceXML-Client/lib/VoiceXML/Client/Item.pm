package VoiceXML::Client::Item;

use VoiceXML::Client;
use VoiceXML::Client::Item::Factory;
use VoiceXML::Client::Flow;
use VoiceXML::Client::Util;

use Hash::Util qw(lock_hash);

use strict;

use vars qw{
		$VERSION
};


$VERSION = $VoiceXML::Client::VERSION;


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

=head2 new XMLELEMENTOBJ PARENTOBJ [PARAMS]


Creates a new instance of the appropriate class.  Parses all children elements and then calls init, passing the 
optional PARAMS href (init() exists to be overridden in subclasses, where required.).


=cut

sub new {
	my $class = shift;
	my $xmlElement = shift || return VoiceXML::Client::Util::error("VoiceXML::Client::Item::Factory::new() Must pass an XML element to new.");
	my $parent = shift;
	my $params = shift;
	
	
	my $self = {};
        
        bless $self, ref $class || $class;
	
	$self->{'type'} = ref $class || $class;
	$self->{'XMLElement'} = $xmlElement;
	$self->{'parent'} = $parent;
	
	
	if ($params && ref $params && exists $params->{'context'})
	{
		$self->{'_context'} =  $params->{'context'};
	} else {
		$self->{'_context'} = undef;
	}
	
	$self->{'currentchild'} = 0;
	
	my $retVal = $self->init($params);
	return $retVal unless ($retVal);  # if init didn't go well, we say so here and skip the kids...
	
	# create children lastly
	$self->createChildren();
	
	return $self;
}

sub getType {
	my $self = shift;
	
	return $self->{'type'};
}

	

sub createChildren {
	my $self = shift;
	my $params = shift;
	
	my $children = $self->{'XMLElement'}->getAllChildren();
	
	my $numChildren = scalar @{$children};

	
	$self->{'children'} = [];
	my $itemCount = 0;
	for (my $i=0; $i<$numChildren; $i++)
	{
		my $name = $children->[$i]->name();
		
		if ($name eq 'var')
		{
			# Variable declaration - ensure we have an interpreter context in this scope
			
			my $varName = $children->[$i]->attribute('name');
			if (defined $varName)
			{
				$self->{'declaredVariables'}->{$varName}++;
			}
			$self->createContext() unless ($self->{'_context'});
		}
			
		my $newItem = VoiceXML::Client::Item::Factory->newItem($name, $children->[$i], $self);
		
		unless (defined $newItem)
		{
			VoiceXML::Client::Util::log_msg("VoiceXML::Client::Item::init() Don't yet know how to deal with '$name' elements - skipping");
			next;
		}
		
		if ($newItem) 
		{
			$self->{'children'}->[$itemCount++] = $newItem;
		} else {
			VoiceXML::Client::Util::log_msg("VoiceXML::Client::Item::init() skipping creation of '$name' element")
				if ($VoiceXML::Client::Debug);
		}

		
	}
	
	return $itemCount;
}

	
	

sub getChildrenImmediate {
	my $self = shift;
	
	return $self->{'children'};
}

sub getChildrenRecursive {
	my $self = shift;
	
	my @results;
	
	foreach my $child (@{$self->{'children'}})
	{
		push @results, $child;
		my $grandChildren = $child->getChildrenRecursive();
		
		push @results, @{$grandChildren};
	}
	
	return \@results;
}


sub getAttribute {
	my $self = shift;
	my $attrname = shift || return undef;
	
	return $self->{'XMLElement'}->attribute($attrname);
}
	

=head2 init [PARAMS]

Called by new(), override in derived classes to implement subclass-specific initialisation.

=cut

sub init {
	my $self = shift;
	my $params = shift;
	
	return 1;
}


sub getRuntime {
	my $self = shift;
	
	if (defined $self->{'_runtime'})
	{
		return $self->{'_runtime'};
	} else {
		return $self->{'parent'}->getRuntime()
			if ($self->{'parent'});
	}

	return undef;
}

sub getContext {
	my $self = shift;
	
	return $self->{'_context'} 
		if (exists $self->{'_context'} && defined $self->{'_context'} && $self->{'_context'});
		
	return $self->{'parent'}->getContext if (defined $self->{'parent'} && $self->{'parent'});
	
	return undef;
}

sub createContext {
	my $self = shift;
	
	my $runtime = $self->getRuntime() || VoiceXML::Client::Util::error("VoiceXML::Client::Item::createContext() Could not find runtime!");
	
	$self->{'_context'} = $runtime->create_context();
	
	return $self->{'_context'};
	
}


sub abortProcessing {
	my $self = shift;
	my $setTo = shift; # optional
	
	if (defined $setTo)
	{
		$self->{'_abortprocessing'} = $setTo;
	}
	
	return $self->{'_abortprocessing'};
}

sub shouldContinueProcessing {
	my $self = shift;
	
	return 0 if ($self->{'_abortprocessing'}); # this item think I should continue...
	
	return $self->{'parent'}->shouldContinueProcessing() if ($self->{'parent'});
	
	return 1;
}

sub reset {
	my $self = shift;

	VoiceXML::Client::Util::log_msg("item reset() called") if ($VoiceXML::Client::Debug > 3);
	
	$self->abortProcessing(0);
	foreach my $child (@{$self->{'children'}})
	{
		$child->reset();
	}
	
	$self->resetChildPositionIndex();
}


sub resetChildPositionIndex {
	my $self = shift;
	
	if (scalar @{$self->{'children'}})
	{
		for (my $i=0; $i <= $self->{'currentchild'}; $i++)
		{
		
			if ($self->{'children'}->[$i])
			{
				$self->{'children'}->[$i]->resetChildPositionIndex();
			}
		}
		
	}
	
	$self->{'currentchild'} = 0;
	
	return ;
}

sub proceedToNextChild {
	my $self = shift;
	
	return $self->{'currentchild'}++;
	
}
	
sub getCurrentChild {
	my $self = shift;
	
	return undef unless ($self->{'currentchild'} < scalar @{$self->{'children'}});
	
	return $self->{'children'}->[$self->{'currentchild'}];
}


sub execute {
	my $self = shift;
	my $handle = shift;
	my $optParms = shift;
	
	
	return $self->executeChildren($handle, $optParms);
}

sub executeChildren {
	my $self = shift;
	my $handle = shift;
	my $optParms = shift;
	
	while ((my $curChild = $self->getCurrentChild()) && $self->shouldContinueProcessing())
	{
		
		my $rv = $curChild->execute($handle, $optParms) ;
	
		
		return $rv if ($rv != $VoiceXML::Client::Flow::Directive{'CONTINUE'});
		
		$self->proceedToNextChild();
	}
	
	return $VoiceXML::Client::Flow::Directive{'CONTINUE'};
	
}





sub getParentVXMLDocument {
	my $self = shift;
	
	if ($self->can('isaVXMLDocument'))
	{
		return $self;
	}
	
	if ($self->{'parent'})
	{
		return $self->{'parent'}->getParentVXMLDocument();
	}
	
	return undef;
}

sub getParentForm {
	my $self = shift;
	
	if ($self->can('isaFormItem'))
	{
		return $self;
	}
	
	if ($self->{'parent'})
	{
		return $self->{'parent'}->getParentForm();
	}
	
	return undef;
}

sub toString {
	my $self = shift;
	
	return $self->{'XMLElement'}->toString();
}

1;
