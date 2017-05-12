#!/usr/bin/env perl
#
# Demonstration of a Salesforce coupling, as test script.  You see the
# initial steps to shape a clean module.
# Contributed by Ciaran Deignan, 18 dec 2013 (slightly modified by MarkOv)
#
# References:
# http://blog.deadlypenguin.com/blog/2012/02/03/salesforce-and-soapui/
# http://wiki.developerforce.com/page/Sample_SOAP_Messages

use warnings;
use strict;
use Data::Dumper;

# preparation
use XML::Compile;
use XML::Compile::WSDL11;      # use WSDL version 1.1
use XML::Compile::SOAP11;      # use SOAP version 1.1
use XML::Compile::Transport::SOAPHTTP;

#my $wsdlfn = 'enterprise-2013-12-16.xml';
my $wsdlfn = 'sandbox-2013-12-18.xml';

## Take login and password from command-line
@ARGV==2 or die "Usage: $0 <username> <password>\n";
my ($U, $P) = @ARGV;

warn "Using XML-Compile version\t%s\n", $XML::Compile::VERSION;
warn "Using XML-Compile-SOAP version\t%s\n", $XML::Compile::SOAP::VERSION;

my $ws   = XML::Compile::WSDL11->new;

## Get WSDL from file...
$ws->addWSDL($wsdlfn);

## Login provides info for the other methods, so needs to be compiled
## separately.
my $ini =  $ws->compileClient('login');

## We need to login first
my ($ret, $trace) = $ini->(username => $U, password=> $P);

#$trace->printErrors(*STDERR); exit;
#print Dumper($ret); exit;

## You may get an error back from the server
if(my $f = $ret->{Fault})
{   my $errname = $f->{_NAME};
    my $error   = $ret->{$errname};
    printf "Error %s (%s)\n", $errname, $f->{faultstring};
#  print Dumper($ret);
    exit;
}


my $login = $ret->{parameters}{result};
my $sh = { sessionId => $login->{sessionId} };

## Information/debugging utilities
#$ws->printIndex; exit;
#print $ws->explain('login', PERL => 'INPUT', recurse => 1); #exit;
#print $ws->explain('logout', PERL => 'INPUT', recurse => 1); exit;
#print $ws->explain('describeSObject', PERL => 'INPUT', recurse => 1); exit;

## Compile all other calls
$ws->compileCalls(endpoint => $login->{serverUrl});

## Best to wrap each of the calls in a convenient function/method, to
## provide an abstract interface to the main program.
my ($ret2, $trace2) = $ws->call(
     'getServerTimestamp'
#    'describeGlobal'
#    'describeSObject', parameters => {sObjectType => 'Account'}
#    'describeSObject', parameters => {sObjectType => 'Machine__c'}
   , SessionHeader => $sh
   );
print Dumper $ret2; 

my ($ret3, $trace3) = $ws->call('logout', SessionHeader => $sh);

#print Dumper($ret3); 
exit 0;


