#!perl -T

use strict;
use warnings;
use Test::More tests => 3;
use Test::Deep;
use Test::Builder::Tester;
use Test::Builder::Tester::Color;

BEGIN {
	use_ok( 'Test::XML::Deep' );
}


{   # good test
    my $file = File::Spec->catfile('t', 'example.xml');
    my $expected = { sometag => array_each( re('.*data$') ),
                     date    => re('\w{3} \w{3} \d{2} \d{2}:\d{2}:\d{2} \w{3} \d{4}'),
                     number  => re('\d+\.\d+'),
                     ignore  => ignore(),
                   };

    cmp_xml_deeply($file, $expected);
}

{   # bad test against same file
    my $file = File::Spec->catfile('t', 'example.xml');
    my $expected = { 'sometag' => [ { attribute => 'value',
                                      content   => 'some data'
                                   },
                                 ]
                   };

    test_out("not ok 1");
    test_fail(+3);
    test_diag(q{Comparing hash keys of $data
# Extra: 'date', 'ignore', 'number'});
    cmp_xml_deeply($file, $expected);
    test_test("fail works");
}


