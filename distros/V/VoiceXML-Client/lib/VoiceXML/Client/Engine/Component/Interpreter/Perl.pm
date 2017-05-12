package VoiceXML::Client::Engine::Component::Interpreter::Perl;

use base qw(VoiceXML::Client::Engine::Component::Interpreter);

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



=head2 new 

=cut

sub runtime {
	my $self = shift;
	my $params = shift;
	
	my $runtime = VoiceXML::Client::Engine::Component::Interpreter::Perl::RunTime->new();
	
	return $runtime;
	
}



package VoiceXML::Client::Engine::Component::Interpreter::Perl::Context;

use base qw (VoiceXML::Client::Engine::Component::Interpreter::Context);

use strict;




sub eval {
	my $self = shift;
	my $code = shift;

	my $comparisonOps = '==|>=?|<=?|!=';
	
	$code =~ s/\s*$//;
	if ($code =~ /^\s*([\w\d\_]+)\s+=\s*'([^']*)'\s*$/)
	{
		my $var = $1;
		my $value = $2;
		$self->{'_perlinterp'}->{'stack'}->{$var} = $value;
	} elsif ($code =~ /^\s*([\w\d\_]+)\s+=\s*(.*)/)
	{
	
		# Assignment
		my $var = $1;
		my $value = " $2";
		
		if ($value =~ /[\s\+\*\/\-\|\&]+/)
		{
			$value =~ s/[^'\w](\w[\w\d\_]+)/$self->{'_perlinterp'}->{'stack'}->{$1}/g;
			my $result;
			my $evalStr = '$result = ' . $value;
			eval $evalStr;
			if ($@)
			{
				die "Error evaluating Code '$evalStr': $@";
			}
			
			$self->{'_perlinterp'}->{'stack'}->{$var} = $result;
		} elsif ($value =~ /^\-?[\d\.]+/)
		{
			$self->{'_perlinterp'}->{'stack'}->{$var} = $value;
		} else {
			$self->{'_perlinterp'}->{'stack'}->{$var} = '';
		}
		
	} elsif ($code =~ /$comparisonOps/)
	{
		my $evalStr = $code;
		########## TODO #############
	}
	
	return 1;
		
	
}


package VoiceXML::Client::Engine::Component::Interpreter::Perl::RunTime;

use base qw (VoiceXML::Client::Engine::Component::Interpreter::RunTime);

use strict;

sub create_context {
	my $self = shift;
	my $stacksize = shift;
	
	my $context = VoiceXML::Client::Engine::Component::Interpreter::Perl::Context->new();
	
	return $context;
	
}

1;

