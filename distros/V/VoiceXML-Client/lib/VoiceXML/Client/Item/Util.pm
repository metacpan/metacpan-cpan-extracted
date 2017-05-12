package VoiceXML::Client::Item::Util;


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

$VERSION = $VoiceXML::Client::VERSION;

sub declareVariable {
	my $class = shift;
	my $item = shift;
	my $name = shift || return;
	my $vxmlDoc = shift || $item->getParentVXMLDocument();
	
	return $vxmlDoc->registerVariable($name);
}


sub resetVariable {
	my $class = shift;
	my $item = shift;
	my $name = shift || return;
	my $vxmlDoc = shift || $item->getParentVXMLDocument();
	
	return $vxmlDoc->clearGlobalVar($name);
}
		

sub assignVariable {
	my $class = shift;
	my $item = shift;
	my $name = shift || return;
	my $expr = shift ;
	my $vxmlDoc = shift || $item->getParentVXMLDocument();
	
	my $varVal;
	if (defined $expr && length($expr))
	{
		$varVal = $class->evaluateExpression($item, $expr, $vxmlDoc);
	} else {
		$varVal = '';
	}
	
	$vxmlDoc->globalVar($name, $varVal);
	
	return $varVal;
}

sub evaluateExpression {
	my $class = shift;
	my $item = shift;
	my $expr = shift ;
	my $vxmlDoc = shift || $item->getParentVXMLDocument();
	
	
	my $varVal;
		
	if (defined $expr && length($expr))
	{
		if ($expr =~ m/^\s*'(.+)'\s*$/)
		{
			$varVal = $1;
			
		} else {
		
			$varVal = $class->doEval($expr, $vxmlDoc);
		}

	} else {
		VoiceXML::Client::Util::log_msg("evaluateExpression() EXPR IS EMPTY") if ($VoiceXML::Client::Debug > 2);
		$varVal = '';
	}
	
	return $varVal;
}
	
sub evaluateCondition {
	my $class = shift;
	my $item = shift;
	my $condition = shift || '';
	my $vxmlDoc = shift || $item->getParentVXMLDocument();
	
	return 0 unless ($condition);
	
	$condition =~s/\&gt;/>/smg;
	$condition =~s/\&lt;/</smg;
	
	$condition =~s/==\s*'/eq '/smg;
	
	my $evRet =  $class->doEval($condition, $vxmlDoc) ;
	
	VoiceXML::Client::Util::log_msg("CONDITION EVALUATED TO " . ($evRet ? 'TRUE' : 'FALSE')) if ($VoiceXML::Client::Debug > 1);
	return $evRet ? 1 : 0;
	
	
}

sub doEval {
	my $class = shift;
	my $code = shift;
	my $vxmlDoc = shift || return;
	
	VoiceXML::Client::Util::log_msg("CHECKING $code") if ($VoiceXML::Client::Debug > 1);
	if ($code !~ m/^\s*(['\w\d_\.\/-]+)(.*)/)
	{
		warn "weird condition '$code'";
		return undef;
	}
	
	if ($code =~ m/^\s*-?\d+(\.\d+)?$/)
	{
		return $code;
	}
	


	my $vname = $1;
	my $rest = $2 || '';
	
	
	my $val = $vxmlDoc->globalVar($1);
	
	
	unless (defined $rest && length($rest))
	{
		if ($VoiceXML::Client::Debug)
		{
			my $valOutputStr = (defined $val) ? $val : '';
			VoiceXML::Client::Util::log_msg("EVAL Returning '$valOutputStr'") ;
		}
		return $val ;
	}
	
	
	my $expr;
	if (defined $val)
	{
		if ($val =~ m/\w/)
		{
			$expr = "'$val'$rest";
		} else {
			if (length($val))
			{
				$expr = $val . $rest;
			} else {
				$expr = "0" . $rest;
			}
		}
	} else {
		if ($rest =~ m/\w/)
		{
			$expr = "''" . $rest;
		} else {
			$expr = "0" . $rest;
		}
	}
	
	
	VoiceXML::Client::Util::log_msg("EVALING '$expr'") if ($VoiceXML::Client::Debug > 1);
	my $retVal = eval $expr;

	
	if ($@)
	{
		warn $@;
		return undef;
	}
	
	return $retVal;
}


1;
