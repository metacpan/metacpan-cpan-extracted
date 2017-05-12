# $Id$

use warnings;
use strict;

use Test::More tests => 10;

use Test::WWW::Selenium::HTML;

{
    my $parser = XML::LibXML->new();

    my $doc1 = 
        $parser->parse_string(<<EOF);
<?xml version="1.0" encoding="UTF-8"?>
<html>
<head></head><body></body>
</html>
EOF

    my @tests = eval {
        Test::WWW::Selenium::HTML::_xml_to_testdata(
            $doc1->getDocumentElement()
        );
    };
    ok($@, 'Died where document contains no namespace');
    like($@, qr/Test document must have an xmlns attribute/,
        'Got correct error message');

    my $doc2 = 
        $parser->parse_string(<<EOF);
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head></head><body></body>
</html>
EOF

    @tests = eval {
        Test::WWW::Selenium::HTML::_xml_to_testdata(
            $doc2->getDocumentElement()
        );
    };
    ok($@, 'Died where document contains no tests');
    like($@, qr/Test document contains no tests/,
        'Got correct error message');

    my $sel = {};
    my $ref = bless $sel, 'Test::WWW::Selenium';
    eval {
        my $asc = Test::WWW::Selenium::HTML->new($ref);
        $asc->run(path => '/non/existent/path/1/2/3/4/5/6/7/8');
    };
    ok($@, 'Died on invalid path');
    like($@, qr/Unable to open/,
        'Got correct error message');

    eval {
        my $asc = Test::WWW::Selenium::HTML->new($ref);
        $asc->run();
    };
    ok($@, 'Died where no path or data provided');
    like($@, qr/Either 'data' or 'path' must be provided/,
        'Got correct error message');

    eval {
        my $asc = Test::WWW::Selenium::HTML->new($ref);
        $asc->run(data => 'asdf', path => 'qwer');
    };
    ok($@, 'Died where both path and data provided');
    like($@, qr/One \(and only one\) of 'data' and 'path' must be provided/,
        'Got correct error message');
}

1;
