# $Id: 06detailed.t 41 2004-05-09 13:28:03Z struan $

use Test::More;
use WebService::Validator::HTML::W3C;

my $test_num = 7;

if ( $ENV{ 'TEST_AUTHOR' } ) {
	 $test_num = 8;
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
	    my $r = $v->validate('http://exo.org.uk/code/www-w3c-validator/invalid.html');

	    unless ($r) {
	        if ($v->validator_error eq "Could not contact validator")
	        {
	            skip "failed to contact validator", 6;
	        }
	    }

	    ok ($r, 'page validated');
	} else {
		$v->num_errors( 1 );
		$v->_content( qq{<?xml version="1.0" encoding="UTF-8"?>
			<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope">
			<env:Body>
			<m:markupvalidationresponse env:encodingStyle="http://www.w3.org/2003/05/soap-encoding" xmlns:m="http://www.w3.org/2005/10/markup-validator">
			    <m:uri>http://exo.org.uk/</m:uri>
			    <m:checkedby>http://qa-dev.w3.org/wmvs/HEAD/</m:checkedby>
			    <m:doctype>-//W3C//DTD XHTML 1.0 Strict//EN</m:doctype>
			    <m:charset>iso-8859-1</m:charset>
			    <m:validity>true</m:validity>
			    <m:errors>
			        <m:errorcount>1</m:errorcount>
			        <m:errorlist>
						<m:error>
							<m:line>11</m:line>
							<m:col>7</m:col>
							<m:message>end tag for "div" omitted, but OMITTAG NO was specified</m:message>
                            <m:messageid>70</m:messageid>
                            <m:explanation>  <![CDATA[
                                  <p class="helpwanted">
                  <a
                    href="http://validator.w3.org/feedback.html?uri=http%3A%2F%2Fexo.org.uk%2Fcode%2Fwww-w3c-validator%2Finvalid.html;errmsg_id=70#errormsg"
                title="Suggest improvements on this error message through our feedback channels" 
                  >&#x2709;</a>
                </p>

                <div class="ve mid-70">
                  <p>
                  You may have neglected to close an element, or perhaps you meant to 
                  "self-close" an element, that is, ending it with "/&gt;" instead of "&gt;".
                </p>
            </div>
                              ]]>
                            </m:explanation>
                            <m:source><![CDATA[&#60;/body<strong title="Position where error was detected.">&#62;</strong>]]></m:source>
						</m:error>
			        </m:errorlist>
			    </m:errors>
			    <m:warnings>
			        <m:warningcount>1</m:warningcount>
			        <m:warninglist>
			  			<m:warning><m:message>Character Encoding mismatch!</m:message></m:warning>
			        </m:warninglist>
			    </m:warnings>
			</m:markupvalidationresponse>
			</env:Body>
			</env:Envelope>
		});
	}
            
    my $err = $v->errors->[0];
    isa_ok($err, 'WebService::Validator::HTML::W3C::Error');
    is($err->line, 11, 'Correct line number');
    is($err->col, 7, 'Correct column');
    is($err->msgid, 70, 'Correct messageid' );
    like($err->msg, qr/end tag for "div" omitted, but OMITTAG NO was specified/,
                    'Correct message');
    like($err->explanation, qr/You may have neglected to close an element, or perhaps you meant to/,
                    'Correct explanation');
    
}
