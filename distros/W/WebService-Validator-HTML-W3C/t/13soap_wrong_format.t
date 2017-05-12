# $Id: 06detailed.t 41 2004-05-09 13:28:03Z struan $

use Test::More tests => 9;
use WebService::Validator::HTML::W3C;

my $v = WebService::Validator::HTML::W3C->new(
            detailed        =>  1,
            output          =>  'xml',
        );

SKIP: {
    skip "TEST_AUTHOR environment variable not defined", 9 unless $ENV{ 'TEST_AUTHOR' };
    skip "XML::XPath not installed", 9 if -f 't/SKIPXPATH';

    ok($v, 'object created');

    my $r = $v->validate('http://exo.org.uk/code/www-w3c-validator/invalid.html');

    unless ($r) {
        if ($v->validator_error eq "Could not contact validator")
        {
            skip "failed to contact validator", 8;
        }
    }

    ok ($r, 'page validated');
            
    $v->_output('soap12');
    is($v->errors, 0, 'Returned 0 for wrong format with SOAP');
    is($v->validator_error, 'Result format does not appear to be SOAP', 'Correct error returned for wrong format with SOAP');

    $r = $v->validate('http://exo.org.uk/code/www-w3c-validator/invalid.html');

    unless ($r) {
        if ($v->validator_error eq "Could not contact validator")
        {
            skip "failed to contact validator", 5;
        }
    }

    ok ($r, 'page validated');
    $v->_output('xml');
    is($v->errors, 0, 'Returned 0 for wrong format with XML');
    is($v->validator_error, 'Result format does not appear to be XML', 'Correct error returned for wrong format with XML');
    is($v->warnings, 0, 'Returned 0 for wrong format with warnings');
    is($v->validator_error, 'Warnings only available with SOAP output format', 'Correct error returned for warnings with xml output');
}
