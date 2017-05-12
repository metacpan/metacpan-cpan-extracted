# $Id: 06detailed.t 41 2004-05-09 13:28:03Z struan $

use Test::More;
use WebService::Validator::HTML::W3C;

my $test_num = 9;

if ( $ENV{ 'TEST_AUTHOR' } ) {
	 $test_num = 10;
}

plan tests => $test_num;

my $v = WebService::Validator::HTML::W3C->new(
            http_timeout    =>  10,
            detailed        =>  1,
            output          =>  'soap12',
        );

SKIP: {
    skip "XML::XPath not installed", $test_num if -f 't/SKIPXPATH';

    ok($v, 'object created');

	if ( $ENV{ 'TEST_AUTHOR' } ) {
		my $r = $v->validate('http://exo.org.uk/code/www-w3c-validator/warning.html');

	    unless ($r) {
	        if ($v->validator_error eq "Could not contact validator")
	        {
	            skip "failed to contact validator", 5;
	        }
	    }

	    ok ($r, 'page validated');
	} else {	
		$v->_content( qq{<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope">
<env:Body>
<m:markupvalidationresponse env:encodingStyle="http://www.w3.org/2003/05/soap-encoding" xmlns:m="http://www.w3.org/2005/10/markup-validator">
    
    <m:uri>http://exo.org.uk/code/www-w3c-validator/warning.html</m:uri>
    <m:checkedby>http://validator.w3.org/</m:checkedby>
    <m:doctype></m:doctype>
    <m:charset>utf-8</m:charset>
    <m:validity>true</m:validity>
    <m:errors>
        <m:errorcount>0</m:errorcount>
        <m:errorlist>
        </m:errorlist>
    </m:errors>
    <m:warnings>
        <m:warningcount>3</m:warningcount>
        <m:warninglist>
  <m:warning><m:messageid>W04</m:messageid><m:message>No Character Encoding Found!
    
      Falling back to 
    
    UTF-8.
  </m:message></m:warning>
  <m:warning><m:messageid>W09</m:messageid><m:message>No DOCTYPE found! Attempting validation with XHTML 1.0 Transitional.</m:message></m:warning>
  <m:warning><m:messageid>W27</m:messageid><m:message>No Character encoding declared at document level</m:message></m:warning>
        </m:warninglist>
    </m:warnings>
</m:markupvalidationresponse>
</env:Body>
</env:Envelope>
		});
	}
              
    my $err = $v->warnings->[1];
    isa_ok($err, 'WebService::Validator::HTML::W3C::Warning');
    is($err->line, undef, 'Correct line number');
    is($err->col, undef, 'Correct column');
    like($err->msg, qr/No DOCTYPE found! Attempting validation with XHTML 1.0/,
                    'Correct message');

    $err = $v->warnings->[2];
    isa_ok($err, 'WebService::Validator::HTML::W3C::Warning');
    is($err->line, undef, 'Correct line number');
    is($err->col, undef, 'Correct column');
    like($err->msg, qr/No Character encoding declared at document level/,
                    'Correct message');

}
