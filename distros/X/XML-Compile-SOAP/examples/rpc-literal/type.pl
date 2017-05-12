#!/usr/bin/perl

use warnings;
use strict;

# just to make it work without installing the module
use lib '../../lib';

# general debugging of XML::Compile modules
#use Log::Report mode => 3;

# Data::Dumper is your friend in understanding the answer
use Data::Dumper;
$Data::Dumper::Indent = 1;

# The features we use
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::Transport::SOAPHTTP;  # we fake an HTTP server

#
# During initiation 'compile time'
#

my $wsdl = XML::Compile::WSDL11->new('type.wsdl');
my $call = $wsdl->compileClient('using_type'
  , transport_hook => \&fake_server # hook simulates a remote server at test
  );

#
# Reuse often at 'run time'
#

my %request =
 ( item =>
   [ { id => 1, name => 'aap'  }
   , { id => 2, name => 'noot' }
   , { id => 3, name => 'mies' }
   ]
 );

my $answer = $call->(list => \%request);

# Useful for debugging.  Also useful to report to syslog
#    my ($answer, $trace) = $call->(\%request);
#    $trace->printTimings;

# When you do not know how the answer is structured
    print Dumper $answer;

if($answer->{Fault})
{   print "Oops\n";
}
else
{   print "*** RESULT=$answer->{using_typeResponse}{result}\n";
}

exit 0;

#
# The below is to simulate a remote server.  All code you need in
# practice is ABOVE this comment.
#

sub fake_server($$)
{  my ($request, $trace) = @_;
   my $content = $request->decoded_content;
   print "*** REQUEST RECEIVED BY SERVER=\n", $content;

   use XML::Compile::SOAP::Util qw/SOAP11ENV/;
   my $soapenv = SOAP11ENV;

   my $server_answer = <<_ANSWER;
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
 <SOAP-ENV:Body>
   <call:using_typeResponse>
     <exp:result xmlns:exp="urn:example:wsdl">5</exp:result>
   </call:using_typeResponse>
 </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
_ANSWER

   print "*** ANSWER SENT BY SERVER=\n", $server_answer;
   HTTP::Response->new(200, 'answer manually created'
    , [ 'Content-Type' => 'text/xml' ], $server_answer);
}
