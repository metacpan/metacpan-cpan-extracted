# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Test::More tests => 32;

BEGIN { use_ok('Text::CSV::Unicode') }

my $tester=Test::More->builder;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $csv = Text::CSV::Unicode->new( { always_quote => 1 } );

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

ok( $csv->version(), 'inheritted version() works');

ok( $csv->isa('Text::CSV::Unicode'), 'creates a Text::CSV::Unicode object' );

my $warn;
sub _warning(&) {
    my $sub = shift;
    local $SIG{__WARN__} = sub { $warn .= $_[0]; };
    $warn = q{};
    return $sub->();
}

_warning { 
    no warnings qw(deprecated);
    Text::CSV::Unicode->new( { binary => 1 } )
};
diag $warn if $warn;
ok (!$warn, q(no 'deprecated' warning) );

my $csv1 = _warning { Text::CSV::Unicode->new( { binary => 1 } ) };
{
    my $warnok = $warn && $warn =~ /\bbinary\sis\sdeprecated\b/;
    diag( $warn || '(no warning)' ) unless $warnok;
    ok ( $warnok, q('binary is deprecated' warning) );
}

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

ok( $csv1->version(), 'inheritted version() works - binary`');

is( Text::CSV::Unicode->VERSION(), $Text::CSV::Unicode::VERSION,
				'class version() works properly');

ok( !$csv1->isa('Text::CSV::Unicode'), 
	'binary=>1 does not create a Text::CSV::Unicode object' );

#
# empty subclass test
#
@Text::CSV::Empty::ISA = qw(Text::CSV::Unicode);

my $empty = Text::CSV::Empty->new();
ok (($empty->version() and $empty->parse('') and $empty->combine('')),
				'empty subclass test');

ok( $empty->isa('Text::CSV::Unicode'),
	'empty subclass creates a Text::CSV::Unicode object' );
