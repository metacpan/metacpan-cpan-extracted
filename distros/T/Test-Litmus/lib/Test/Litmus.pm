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

# import these into the main namespace so our users don't have to explicitly 
# use them as well...
BEGIN {
	package main;
	use Test::Litmus::Log;
	use Test::Litmus::Result;
}

package Test::Litmus;

use v5.6.1;
use strict;

use HTTP::Request::Common qw(POST);
use LWP::UserAgent;

our $VERSION = '0.03';

sub new {
	my $class = shift;
	my %args = @_;
	my $self = {};
	bless $self;
	
	$self->{'server'} = $args{'-server'} || 
		'http://litmus.mozilla.org/process_test.cgi';
	$self->{'action'} = $args{'-action'} || 'submit';
	$self->requiredField('machinename', %args);
	$self->requiredField('username', %args);
	$self->requiredField('authtoken', %args);	
	
	return $self;
}

sub sysconfig {
	my $self = shift;
	my %args = @_;
	
	$self->requiredField('product', %args);
	$self->requiredField('platform', %args);
	$self->requiredField('opsys', %args);
	$self->requiredField('branch', %args);
	$self->requiredField('buildid', %args);
	$self->requiredField('locale', %args);
	
	$self->{'buildtype'} = $args{'-buildtype'};
}

# add a Test::Litmus::Result object to ourselves
sub addResult {
	my $self = shift;
	my $result = shift;
	push(@{$self->{'results'}}, $result);
}

# add a Test::Litmus::Log object to ourselves
sub addLog {
	my $self = shift;
	my $log = shift;
	push(@{$self->{'logs'}}, $log);
}

# add fieldname to $self unless its missing, at which point we die
sub requiredField {
	my $self = shift;
	my $fieldname = shift;
	my %args = @_;
	
	$self->{$fieldname} = $args{'-'.$fieldname} || 
		die "You must specify a $fieldname";
}

sub errstr {
	my $self = shift;
	return $self->{'response'}->content;
}

sub toXML {
	my $self = shift;
	my $x;
	
	$x  = '<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>'."\n";
 	$x .= '<!DOCTYPE litmusresults PUBLIC 
           "-//Mozilla Corporation//Litmus Result Submission DTD//EN/"
           "http://litmus.mozilla.org/litmus_results.dtd">'."\n";
    $x .= '<litmusresults action="'.$self->{'action'}.'" useragent="'.
    	'Test::Litmus/'.$VERSION.' ('.$self->{'machinename'}.')" '.
    	'machinename="'.$self->{'machinename'}.'">'."\n";
    $x .= '  <testresults username="'.$self->{'username'}.'"'."\n";
    $x .= '     authtoken="'.$self->{'authtoken'}.'"'."\n";
    $x .= '     product="'.$self->{'product'}.'"'."\n";
    $x .= '     platform="'.$self->{'platform'}.'"'."\n";
    $x .= '     opsys="'.$self->{'opsys'}.'"'."\n";
    $x .= '     branch="'.$self->{'branch'}.'"'."\n";
    $x .= '     buildid="'.$self->{'buildid'}.'"'."\n";
    $x .= '     locale="'.$self->{'locale'}.'"';
    if ($self->{'buildtype'}) {
    	$x .= "\n".'     buildtype="'.$self->{'buildtype'}.'"'.">\n";
    } else {
    	$x .= ">\n";
    }
    
    if ($self->{'logs'}) {
		my @logs = @{$self->{'logs'}};
		foreach my $curlog (@logs) {
			$x .= $curlog->toXML();
		}
    }
    
    my @results = @{$self->{'results'}}; 
    foreach my $curresult (@results) {
    	$x .= $curresult->toXML();
    }
    
    $x .= '  </testresults>'."\n";
    $x .= '</litmusresults>'."\n";
    
    return $x;
}

sub submit {
	my $self = shift;
	$self->{'ua'} = new LWP::UserAgent;
	$self->{'req'} = POST $self->{'server'}, [ data => $self->toXML() ];
	$self->{'response'} = $self->{'ua'}->request($self->{'req'});
	
	if ($self->{'response'}->content =~ /^ok/i) { return 1 }
	elsif ($self->{'response'}->content =~ /^Error processing result/i) { return 0 }
	else { return undef }
}

1;
__END__

=head1 NAME

Test::Litmus - Perl module to submit test results to the Litmus testcase 
management tool

=head1 SYNOPSIS

  use Test::Litmus;
  
  $t = Test::Litmus->new(-machinename => 'mycomputer',
  						 -username => 'user', 
  						 -authtoken => 'token',
  			# optional # -server => 'http://litmus.mozilla.org/process_test.cgi', 
  			# optional # -action => 'submit');
  			
  $t->sysconfig(-product => 'Firefox',
  				-platform => 'Windows', 
  				-opsys => 'Windows XP', 
  				-branch => 'Trunk', 
  				-buildid => '2006061314',
  				-buildtype => 'debug cvs',
  				-locale => 'en-US');
  
  my $result = Test::Litmus::Result->new(
  							-isAutomatedResult => 1, # optional
  							-testid => 27,
  							-resultstatus => 'pass', # valid results are 'pass'
  													 # or 'fail'
  							-exitstatus => 0,
  							-duration => 666,
  							-timestamp => 20051111150944, # optional (default: current time)
  							-comment => 'optional comment here', # optional
  							-bugnumber => 300010, 				 # optional
  							-log => [Test::Litmus::Log->new(	 # optional
  										-type => 'STDOUT',
  										-data => 'foobar'),
  									 Test::Litmus::Log->new(
  									 	-type => 'Extensions Installed',
  									 	-data => 'log information here')]
  							);
  $t->addResult($result);
  # $t->addResult($someOtherResult);
  # etc...
  
  # add log information that should be linked with 
  # all results (i.e. env variables, config info)
  $t->addLog(Test::Litmus::Log->new(
  								-type => 'STDOUT',
  								-data => 'log data')); 
  
  my $res = $t->submit();
  
  # $res is 0 for non-fatal errors (some results were submitted), and 
  # undef for fatal errors (no results were submitted successfully)
  
  if ($t->errstr()) { die $t->errstr() }

=head1 DESCRIPTION

The Test::Litmus module handles the submission of test results to Mozilla's 
Litmus testcase management system.

=head1 SEE ALSO
L<http://litmus.mozilla.org>
L<http://wiki.mozilla.org/Litmus>
L<http://wiki.mozilla.org/Litmus:Web_Services>

=head1 AUTHOR

Zach Lipton, E<lt>zach@zachlipton.comE<gt>

=head1 COPYRIGHT AND LICENSE

The contents of this file are subject to the Mozilla Public License Version 
1.1 (the "License"); you may not use this file except in compliance with 
the License. You may obtain a copy of the License at 
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
for the specific language governing rights and limitations under the
License.

The Original Code is Test::Litmus.

The Initial Developer of the Original Code is The Mozilla Corporation.

Portions created by the Initial Developer are Copyright (C) 2006
the Initial Developer. All Rights Reserved.

Contributor(s): Zach Lipton <zach@zachlipton.com>

=cut
