# The contents of this file are subject to the Mozilla Public License Version 
# 1.1 (the "License"); you may not use this file except in compliance with 
# the License. You may obtain a copy of the License at 
# http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS IS" basis,
# WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
# for the specific language governing rights and limitations under the
# License.
# 
# The Original Code is Test::Litmus.
# 
# The Initial Developer of the Original Code is The Mozilla Corporation.
# 
# Portions created by the Initial Developer are Copyright (C) 2006
# the Initial Developer. All Rights Reserved.
# 
# Contributor(s): Zach Lipton <zach@zachlipton.com>

package Test::Litmus::Result;

use v5.6.1;
use strict;

our $VERSION = '0.01';

sub new {
	my $class = shift;
	my %args = @_;
	my $self = {};
	bless $self;
	
	$self->requiredField('testid', %args);
	if ($args{'-resultstatus'} =~ /pass/i) { $self->{'resultstatus'} = 'Pass' }
	elsif ($args{'-resultstatus'} =~ /fail/i) { $self->{'resultstatus'} = 'Fail' }
	else { die "You must specify a valid resultstatus (pass or fail)" }
	$self->requiredField('exitstatus', %args);	
	$self->requiredField('duration', %args);
	
	# if no timestamp specified, use the current time
	if ($args{'-timestamp'}) { $self->{'timestamp'} = $args{'-timestamp'} } 
	else { 
		my @t = localtime(time);
		# YYYYMMDDHHMMSS format
		$self->{'timestamp'} = ($t[5]+1900).leadZero($t[4]+1).leadZero($t[3]).
			leadZero($t[2]).leadZero($t[1]).leadZero($t[0]);
	}
	
	$self->{'comment'} = $args{'-comment'};
	$self->{'bugnumber'} = $args{'-bugnumber'};
	$self->{'logs'} = $args{'-log'};
	
	$self->{'automated'} = defined $args{'-isAutomatedResult'} ? 
		$args{'-isAutomatedResult'} : 1;
	
	return $self;
}

sub requiredField {
	my $self = shift;
	my $fieldname = shift;
	my %args = @_;
	
	die "You must specify a $fieldname" if not defined $args{'-'.$fieldname};
	
	$self->{$fieldname} = $args{'-'.$fieldname};
}

# add a leading zero to date parts if only one character is present:
sub leadZero {
	my $num = shift;
	if (length($num) == 1) { return (0).$num; } 
	return $num;
}

sub toXML {
	my $self = shift;
	my $x; 
	
	$x  = '<result testid="'.$self->{'testid'}.'"'."\n";
	$x .= '		 is_automated_result="'.$self->{'automated'}.'"'."\n";
	$x .= '      resultstatus="'.$self->{'resultstatus'}.'"'."\n";
	$x .= '      exitstatus="'.$self->{'exitstatus'}.'"'."\n";
	$x .= '      duration="'.$self->{'duration'}.'"'."\n";
	$x .= '      timestamp="'.$self->{'timestamp'}.'">'."\n";
	
	if ($self->{'comment'}) {
		$x .= '  <comment>'.$self->{'comment'}.'</comment>'."\n";
	}
	
	if ($self->{'bugnumber'}) {
		$x .= '  <bugnumber>'.$self->{'bugnumber'}.'</bugnumber>'."\n";
	}
	
	if ($self->{'logs'}) {
		my @logs = @{$self->{'logs'}};
		foreach my $curlog (@logs) {
			$x .= $curlog->toXML();
		}
    }
	
	$x .= '</result>'."\n";
}

1;
