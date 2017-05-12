
package VoiceXML::Client::Item::Grammar;


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
	
	my $mode = $self->{'XMLElement'}->attribute('mode');

	return undef unless (defined $mode);
	
	unless ($mode eq 'dtmf')
	{
		warn "Only DTMF mode grammars currently supported";
		return undef;
	}
	
	$self->{'mode'} = $mode;
	
	$self->{'id'} = ($self->{'XMLElement'}->attribute('id') || int(rand(999999)) . time());
	
	$self->{'rules'} = {};
	
	return 1;
	
}

sub registerRule {
	my $self = shift;
	my $id = shift;
	my $rule = shift || return;
	
	$self->{'rules'}->{$id} = $rule;
}

sub isValidInput {
	my $self = shift;
	my $input = shift || '';
	
	warn "CHECKING GRAMMAR $self->{'id'}";
	
	my $testcount = 0;
	while (my ($rid, $rule) = each %{$self->{'rules'}})
	{
		$testcount++;
		return 1 if ($rule->isValidInput($input));
	}
	
	return 0 if ($testcount); # failed all rules
	
	# no rules set... always good I say.
	return 1;
}
	

sub execute {
	my $self = shift;
	my $handle = shift;
	my $optParams = shift;
	
	
	my $parentForm = $self->getParentForm();
	$parentForm->registerGrammar($self->{'id'}, $self);
	
	# skip over kids...
	return $VoiceXML::Client::Flow::Directive{'CONTINUE'};
}
	



1;
