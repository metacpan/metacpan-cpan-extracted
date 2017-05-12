package Netscape::eg::Noop;
use strict;
use Netscape::Server qw/:all/;

sub handler {
    my($pb, $sn, $rq) = @_;
       return REQ_NOACTION;
       }

1;
