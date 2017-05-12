package Netscape::eg::HelloWorld;
use strict;
use Netscape::Server qw/:all/;

sub content_type {
    my($pb, $sn, $rq) = @_;
    
    # --- Set the content type as configured
    my $type = $pb->{'type'};
    defined $type or
	return REQ_ABORTED;
    $rq->srvhdrs('content-type', $type);
    return REQ_PROCEED;
}

sub handler {
    my($pb, $sn, $rq) = @_;
    my($proceed);
    
    # --- Set status to 200 OK
    $sn->protocol_status($rq, PROTOCOL_OK);
    # --- Initiate response
    $proceed = $sn->protocol_start_response($rq);
    if ($proceed == REQ_PROCEED) {
	$sn->net_write("<h1>Hello World</h1>\n");
	return REQ_PROCEED;
    } elsif ($proceed == REQ_NOACTION) {
	# --- Client probably did an if-modified request
	return REQ_PROCEED;
    } else {
	# --- Yikes! Something bad has happened
	return $proceed;
    }
}

1;
