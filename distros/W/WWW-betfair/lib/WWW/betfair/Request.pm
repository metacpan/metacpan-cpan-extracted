package WWW::betfair::Request;
use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request;

=head2 new_request

Sends HTTP requests to the betfair API and parses the returning XML into a Perl hashreference.
 
=cut


sub new_request
{
    my ($uri, $action, $xmlmessage) = @_;
    
    # build and send request
    my $userAgent = LWP::UserAgent->new;
    $userAgent->env_proxy;
    my $request = HTTP::Request->new( POST => $uri );
    $request->header( SOAPAction => '"' . $action .'"' );
    $request->header(Accept_Encoding => "gzip");
    $request->content($xmlmessage);
    $request->content_type("text/xml; charset=utf-8");
    return $userAgent->request($request);
}
1;
