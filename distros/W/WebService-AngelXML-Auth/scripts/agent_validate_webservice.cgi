#!/usr/bin/perl -w

=head1 NAME

agent_validate_webservice.cgi - WebService::AngelXML::Auth example

=cut

use strict;
use WebService::AngelXML::Auth;
my $ws=WebService::AngelXML::Auth->new();

### This section is just to make a nice example
$ws->mimetype("text/xml");      #Because MSIE likes this better.

if (defined $ENV{'QUERY_STRING'}) { #running from browser
  unless ($ENV{'QUERY_STRING'}) {
    my %param=(store_id=>7861, associate_id=>5546, next_page=>100);
    $ws->cgi->param(-name=>$_, -value=>$param{$_}) foreach keys %param;
    print $ws->cgi->redirect($ws->cgi->url(-full=>1, -query=>1));
    exit;
  }
} else { #running from command line
  $ws->id(1) unless $ws->id;      #some defaults 
  $ws->pin(1) unless $ws->pin;
  $ws->page(1) unless $ws->page;
}
### section end

if ($ws->id == $ws->pin) {      #use an auth source like LDAP or database
  $ws->allow(1);
} else {
  $ws->deny(1);
}

print $ws->header,
      $ws->response;

=head1 SAMPLE OUTPUT

  Content-Type: text/xml
  
  <?xml version='1.0' standalone='yes'?>
  <ANGELXML>
    <MESSAGE>
      <GOTO destination="100" />
      <PLAY>
        <PROMPT type="text">.</PROMPT>
      </PLAY>
    </MESSAGE>
    <VARIABLES>
      <VAR name="status_code" value="0" />
    </VARIABLES>
  </ANGELXML>

=cut
