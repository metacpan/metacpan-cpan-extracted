package TestApReq::request;

use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::Constants qw(OK M_POST DECLINED);

use Apache::Request ();

sub handler {
    my $r = shift;
    my $apr = Apache::Request->new($r);

    $r->send_http_header('text/plain');

    my $test  = $apr->param('test');
    my $value = $apr->param('value');

    return DECLINED unless defined $test;

    if ($test eq 'param') {
        $r->print($value);
    }
    elsif ($test eq 'upload') {
        my $upload = $apr->upload;
        my $fh = $upload->fh;
        local $/;
        my $data = <$fh>;
        $r->print($data);
    } 
    else {
        
    }

    return OK;
}
1;
__END__
