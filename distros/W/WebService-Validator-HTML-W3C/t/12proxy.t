# $Id$

use Test::More tests => 2;
use WebService::Validator::HTML::W3C;
eval "use HTTP::Proxy 0.16";

SKIP: {
	skip "TEST_AUTHOR environment variable not defined", 2 unless $ENV{ 'TEST_AUTHOR' };
    skip "HTTP::Proxy required for testing proxy", 2 if $@;
    my $test = Test::Builder->new;

    # this is to work around tests in forked processes
    $test->use_numbers(0);
    $test->no_ending(1);

    my $p = HTTP::Proxy->new( port => 3228, max_connections => 1 );
    $p->init;

    my $pid = fork;
    if ( $pid == 0 ) {
        $p->start;
        exit 0;
    } else {
        sleep 1; # just to make proxy is started
        my $v = WebService::Validator::HTML::W3C->new( proxy => $p->url );

        my $r = $v->validate('http://exo.org.uk/code/www-w3c-validator/valid.html');

        unless ($r) {
            if ($v->validator_error eq "Could not contact validator")
            {
                skip "failed to contact validator", 2;
            }
        }

        ok($r, 'validates page');
        ok($v->is_valid, 'page is valid');
        wait;
    }
}
