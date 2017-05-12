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

package Test::Litmus::Log;

use v5.6.1;
use strict;

our $VERSION = '0.01';

sub new {
	my $class = shift;
	my %args = @_;
	my $self = {};
	bless $self;
	
	$self->requiredField('type', %args);
	$self->requiredField('data', %args);
	
	return $self;
}

sub toXML {
	my $self = shift;
	my $x;
	
	$x  = '<log logtype="'.$self->{'type'}.'">'."\n";
	$x .= '  <![CDATA['.$self->{'data'}.']]>'."\n";
	$x .= '</log>'."\n";
	
	return $x;
}

sub requiredField {
	my $self = shift;
	my $fieldname = shift;
	my %args = @_;
	
	$self->{$fieldname} = $args{'-'.$fieldname} || 
		die "You must specify a $fieldname";
}

1;
