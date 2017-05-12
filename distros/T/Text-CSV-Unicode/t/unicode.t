# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test::More;

BEGIN{ 
    unless( $ENV{TEST_CSV_UNICODE_SKIP_REQUIRES} ) {
	no warnings qw(portable); 
        plan skip_all => 'requires perl v5.8.0'
                unless eval{ require 5.8.0 }; 
        plan skip_all => 'charnames required'
                unless eval{ require charnames }; 
    }
    plan tests => 25;
    use_ok('Text::CSV::Unicode')
}
my $tester=Test::More->builder;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $csv = Text::CSV::Unicode->new();

ok (! $csv->combine(),		'fail - missing argument');
ok (! $csv->combine('abc', "def\n", 'ghi'),
				'fail - bad character');

ok ($csv->combine('') && ($csv->string eq q("")),
				'succeed');
ok ($csv->combine('', '') && ($csv->string eq q("","")),
				'succeed');
ok ($csv->combine('', 'I said, "Hi!"', '') &&
    ($csv->string eq q("","I said, ""Hi!""","")),
				'succeed');

ok ($csv->combine('"', 'abc') && ($csv->string eq q("""","abc")),
				'succeed');
ok ($csv->combine('abc', '"') && ($csv->string eq q("abc","""")),
				'succeed');

ok ($csv->combine('abc', 'def', 'ghi') &&
    ($csv->string eq q("abc","def","ghi")),
				'succeed');
ok ($csv->combine("abc\tdef", 'ghi') &&
    ($csv->string eq qq("abc\tdef","ghi")),
				'succeed');

ok (! $csv->parse(),		'fail - missing argument');
ok (! $csv->parse('"abc'),	'fail - missing closing double-quote');
ok (! $csv->parse('ab"c'),	'fail - double-quote outside of double-quotes');
ok (! $csv->parse('"ab"c"'),	'fail - bad character sequence');

ok (! $csv->parse(qq("abc\nc")),'fail - bad character');
{ my $test = $tester->current_test;
  ok (! $csv->status(),		"fail - test $test should have failed");
}

ok (($csv->parse(q(",")) and ($csv->fields())[0] eq ','),
				'success');

ok (($csv->parse(qq("","I said,\t""Hi!""","")) and
    ($csv->fields())[0] eq '' and
    ($csv->fields())[1] eq qq(I said,\t"Hi!") and
    ($csv->fields())[2] eq ''),	'success');

{ my $test = $tester->current_test;
  ok ($csv->status(),		"success - test $test should have succeeded");
}

is( $csv->version(), $Text::CSV::Unicode::VERSION,
				'inheritted version() works properly');

my $csv1 = Text::CSV::Unicode->new( { binary => 1 } );
ok ($csv1->parse(qq("abc\nc")),	'success - \n allowed');

{ my $test = $tester->current_test;
  ok ($csv1->status(),		"success - test $test should have succeeded");
}

ok (($csv1->parse(qq("","I said,\n""Hi!""","")) and
    ($csv1->fields())[0] eq '' and
    ($csv1->fields())[1] eq qq(I said,\n"Hi!") and
    ($csv1->fields())[2] eq ''),'success - embedded \n');

{ my $test = $tester->current_test;
  ok ($csv1->status(),		"success - test $test should have succeeded");
}

#
# empty subclass test
#
package Empty_Subclass;
our @ISA = qw(Text::CSV::Unicode);

package main;
my $empty = Empty_Subclass->new();
ok (($empty->version() and $empty->parse('') and $empty->combine('')),
				'empty subclass test');

# $Id: unicode.t 290 2012-02-19 22:25:30Z robin $
