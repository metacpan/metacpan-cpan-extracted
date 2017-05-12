package Netscape::eg::Redirect;
use strict;
use Netscape::Server qw/:all/;

sub handler {
    my($pb, $sn, $rq) = @_;

    my $ppath = $rq->vars('ppath');
    my $from = $pb->{'from'};
    my $url = $pb->{'url'};
    my $alt = $pb->{'alt'};

    if (not defined $from or not defined $url) {
	log_error(LOG_MISCONFIG, "handler", $sn, $rq,
		  'missing parameter (need from, url)');
	return REQ_ABORTED;
    }

    # --- Here's where the poor sucker using raw NSAPI has to
    # --- resort to the utterly bogus shexp_cmp()
    $ppath =~ /^$from/o or
	return REQ_NOACTION;

    # --- Get the user agent
    defined(my $ua = $rq->headers('user-agent')) or
	return REQ_ABORTED;

    # --- NSAPI has a built-in that looks for Mozilla-like browser,
    # --- but MSIE fools it.  However, now we can use a full Perl
    # --- regular expression here if we want
    if ($ua =~ /Mozilla/ and $ua !~ /MSIE/) {
	$rq->protocol_status($sn, PROTOCOL_REDIRECT);
	$rq->vars('url', $url);
	return REQ_ABORTED;
    }
    
    # --- No match.  Could be MSIE or Lynx or whomever.
    if (defined $alt) {
	# --- Rewrite the request string
	$rq->vars('ppath', $alt);
	return REQ_NOACTION;
    }
    
    # --- Else do nothing
    return REQ_NOACTION;
}

1;
