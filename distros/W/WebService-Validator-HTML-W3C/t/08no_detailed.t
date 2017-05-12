# $Id$

use Test::More tests => 7;

BEGIN {
        eval "use Test::Warn";
}

SKIP: {
    use WebService::Validator::HTML::W3C;

    my $v = WebService::Validator::HTML::W3C->new(
                http_timeout    =>  10,
            );

    skip "TEST_AUTHOR environment variable not defined", 7 unless $ENV{ 'TEST_AUTHOR'};
    skip "Test:Warn not install", 7 if -f 't/SKIPWARN';
    skip "XML::XPath not installed", 7 if -f 't/SKIPXPATH';

    ok($v, 'object created');

    my $r = $v->validate('http://exo.org.uk/code/www-w3c-validator/invalid.html');

    unless ($r) {
        if ($v->validator_error eq "Could not contact validator")
        {
            skip "failed to contact validator", 6;
        }
    }

    ok ($r, 'page validated');
            
    my $err;
    warning_is { $err = $v->errors->[0]; } "You should set detailed when initalising if you intend to use the errors method", "set detailed warning";
    isa_ok($err, 'WebService::Validator::HTML::W3C::Error');
    is($err->line, 11, 'Correct line number');
    is($err->col, 7, 'Correct column');
    like($err->msg, qr/end tag for "div" omitted, but OMITTAG NO was specified/,
                    'Correct message');
    
}
