package Netscape::eg::Test;
use strict;
use Netscape::Server qw/:all/;

sub handler {
    my($pb, $sn, $rq) = @_;
    my($proceed);
    
    # --- Set status to 200 OK
    $sn->protocol_status($rq, PROTOCOL_OK);
    
    # --- Initiate response
    $proceed = $sn->protocol_start_response($rq);
    if ($proceed == REQ_PROCEED) {

	my $content = '<h1>Contents of Request($rq) hash</h1>' . "\n";
	my $key;
	my $curhash;

	##-- print contents of $rq hash
	$content .= '$rq->auth_type = ' . $rq->auth_type . "<br>\n";
	$content .= '$rq->path_info = ' . $rq->path_info . "<br>\n";
	$content .= '$rq->remote_user = ' . $rq->remote_user . "<br>\n";
	$content .= '$rq->request_method = ' . $rq->request_method . "<br>\n";
	$content .= '$rq->server_protocol = ' . $rq->server_protocol . "<br>\n";
	$content .= '$rq->user_agent = ' . $rq->user_agent; $content . "<br>\n";

	## print contents of $rq->vars hash
	$content .= '<h1>Contents of $rq->vars hash</h1>' . "\n";
	$curhash = $rq->vars;
	$content .= dumpHash($curhash);

	## print contents of $rq->reqpb hash
	$content .= '<h1>Contents of $rq->reqpb hash</h1>' . "\n";
	$curhash = $rq->reqpb;
	$content .= dumpHash($curhash);

	## print contents of $rq->headers hash
	$content .= '<h1>Contents of $rq->headers hash</h1>' . "\n";
	$curhash = $rq->headers;
	$content .= dumpHash($curhash);

	## print contents of $rq->srvhdrs hash
	$content .= '<h1>Contents of $rq->srvhdrs hash</h1>' . "\n";
	$curhash = $rq->srvhdrs;
	$content .= dumpHash($curhash);

	##-- print contents of $sn hash
	$content .= '<h1>Contents of Session ($sn) hash</h1>' . "\n";
	$content .= '$sn->remote_host = ' . $sn->remote_host . "<br>\n";
	$content .= '$sn->remote_addr = ' . $sn->remote_addr . "<br>\n";

	##-- test writing to errors log file
	$content .= '<h1>Testing log_error() ...</h1>' . "\n";
	my $msg = 'log_error() works!' . "\n";
	if( log_error(LOG_INFORM, 'Netscape::eg::Test', $sn, $rq, $msg) ) {
		$content .= 'Sucess! wrote the message <b>' . $msg . '</b> to errors log file<br>' . "\n";
		}
	else {
		$content .= 'Failed! could not write message to errors log file<br>' . "\n";
		}

	## write out content
	$sn->net_write($content);

	return REQ_PROCEED;

    } elsif ($proceed == REQ_NOACTION) {
	# --- Client probably did an if-modified request
	return REQ_PROCEED;
    } else {
	# --- Yikes! Something bad has happened
	return $proceed;
    }
}

sub dumpHash {
my($curhash) = @_;
my $key;
my $content = '';
foreach $key (sort(keys(%$curhash))) {
	$content .= '$rq->vars{' . $key . '} = ' . $curhash->{$key} . "<br>\n";
	}
$content;
}

1;
