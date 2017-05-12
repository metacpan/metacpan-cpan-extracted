package TestApReq::big_input;

use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;

use Apache::Cookie ();
use Apache::Request ();


sub handler {
    my $r = shift;
    my $apr = Apache::Request->new($r);

    my $len = 0;
    for ($apr->param) {
        $len += length($_) + length($apr->param($_)) + 2; # +2 ('=' and '&')
    }
    $len--; # the stick with two ends one '&' char off

    $r->send_http_header('text/plain');
    $r->print($len);

    return 0;
}

1;

__END__
