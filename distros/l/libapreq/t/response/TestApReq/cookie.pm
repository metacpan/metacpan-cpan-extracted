package TestApReq::cookie;

use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;

use Apache::Cookie ();
use Apache::Request ();


sub handler {
    my $r = shift;
    my $apr = Apache::Request->new($r);
    my %cookies = Apache::Cookie->fetch;

    $r->send_http_header('text/plain');

    my $test = $apr->param('test');
    my $key  = $apr->param('key');

#    return DECLINED unless defined $test;

    if ($test eq 'basic') {
        if ($cookies{$key}) {
            $r->print($cookies{$key}->value);
        }
    }


    return 0;
}

1;

__END__
