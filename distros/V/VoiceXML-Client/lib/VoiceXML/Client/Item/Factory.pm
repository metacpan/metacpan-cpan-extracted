package VoiceXML::Client::Item::Factory;

use VoiceXML::Client::Item::Form;
use VoiceXML::Client::Item::Prompt;
use VoiceXML::Client::Item::Field;
use VoiceXML::Client::Item::Break;
use VoiceXML::Client::Item::Option;
use VoiceXML::Client::Item::Filled;
use VoiceXML::Client::Item::If;
use VoiceXML::Client::Item::Elseif;
use VoiceXML::Client::Item::Else;
use VoiceXML::Client::Item::Goto;
use VoiceXML::Client::Item::Submit;
use VoiceXML::Client::Item::Disconnect;
use VoiceXML::Client::Item::Audio;
use VoiceXML::Client::Item::Record;
use VoiceXML::Client::Item::Var;
use VoiceXML::Client::Item::Clear;
use VoiceXML::Client::Item::Block;
use VoiceXML::Client::Item::NoInput;
use VoiceXML::Client::Item::NoMatch;
use VoiceXML::Client::Item::Reprompt;
use VoiceXML::Client::Item::Assign;
use VoiceXML::Client::Item::SubDialog;
use VoiceXML::Client::Item::Return;

use VoiceXML::Client::Item::Grammar;
use VoiceXML::Client::Item::Grammar::Rule;


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



=head2 new 

=cut

sub new {
	my $class = shift;
	my $defaultItemParent = shift;
	
	my $self = {};
        
        bless $self, ref $class || $class;
	
	$self->{'defaultItemParent'} = $defaultItemParent;
	
	return $self;
}




=head2 newItem NAME XMLELEMENT

Creates a new instance.


=cut

sub newItem {
	my $class = shift;
	my $name = shift;
	my $xmlElement = shift || return VoiceXML::Client::Util::error("VoiceXML::Client::Item::Factory::newItem() Must pass an XML element to new.");
	my $parent = shift ;
	
	if (! $parent && ref $class)
	{
		$parent = $class->{'defaultItemParent'};
	}
	
	return VoiceXML::Client::Util::error("VoiceXML::Client::Item::Factory::newItem() Must pass a name for form object to new.")
		unless (defined $name);
		
	
	my $sub = "genitem_" . lc($name);
	
	return $class->$sub($xmlElement, $parent) if ($class->can($sub));
	
	return undef;
	
}

sub genitem_prompt {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::Prompt->new($xmlElement, $parent);
}


sub genitem_field {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::Field->new($xmlElement, $parent);
}

sub genitem_form {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::Form->new($xmlElement, $parent);
}

sub genitem_break {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::->new($xmlElement, $parent);
}

sub genitem_option {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::Option->new($xmlElement, $parent);
}

sub genitem_filled {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::Filled->new($xmlElement, $parent);
}


	
sub genitem_if {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::If->new($xmlElement, $parent);
}

sub genitem_elseif {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::Elseif->new($xmlElement, $parent);
}

sub genitem_else {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::Else->new($xmlElement, $parent);
}

sub genitem_goto {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::Goto->new($xmlElement, $parent);
}

sub genitem_audio {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::Audio->new($xmlElement, $parent);
}

sub genitem_record {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::Record->new($xmlElement, $parent);
}

sub genitem_var {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::Var->new($xmlElement, $parent);
}

sub genitem_clear {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::Clear->new($xmlElement, $parent);
}
sub genitem_block {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::Block->new($xmlElement, $parent);
}

sub genitem_submit {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::Submit->new($xmlElement, $parent);
}

sub genitem_noinput {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::NoInput->new($xmlElement, $parent);
}


sub genitem_reprompt {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::Reprompt->new($xmlElement, $parent);
}

sub genitem_assign {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::Assign->new($xmlElement, $parent);
}


sub genitem_grammar {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::Grammar->new($xmlElement, $parent);
}


sub genitem_rule {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::Grammar::Rule->new($xmlElement, $parent);
}



sub genitem_nomatch {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::NoMatch->new($xmlElement, $parent);
}


sub genitem_subdialog {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::SubDialog->new($xmlElement, $parent);
}



sub genitem_return {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::Return->new($xmlElement, $parent);
}






sub genitem_disconnect {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return VoiceXML::Client::Item::Disconnect->new($xmlElement, $parent);
}


sub genitem_exit {
	my $class = shift;
	my $xmlElement = shift || return;
	my $parent = shift ;
	
	return $class->genitem_disconnect($xmlElement, $parent);
}



1;
