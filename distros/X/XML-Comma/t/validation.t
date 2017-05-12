use strict;
use File::Path;

use Test::More 'no_plan';

use lib ".test/lib/";

use XML::Comma;
use XML::Comma::Util qw( dbg );

my $doc_block = <<END;
<_test_validation>
  <sing>blah blah</sing>

  <plu>blah</plu>
  <plu>blah</plu>
  <plu>blah</plu>

  <zero_field>a true value</zero_field>

  <nested>
    <nested_sing>nah</nested_sing>
    <nested_plu>nah</nested_plu><nested_plu>nah</nested_plu>
  </nested>

</_test_validation>
END

###########

## make def
my $def = XML::Comma::Def->read ( name => '_test_validation' );
ok($def);

## create the doc (which tests permitting plural creation)
my $doc = XML::Comma::Doc->new ( block=>$doc_block );
ok($doc);

## shouldn't be able to add more to singular elements
eval { $doc->add_element('sing') };
ok($@);
eval { $doc->element('nested')->add_element('nested_sing') }; 
ok($@);
## but should be able to add a plural one
$doc->element('nested')->add_element('nested_plu')->set('added and set');
ok("we can add a plural element");

## date8
my @apms = $doc->element('d8')->applied_macros();
ok($apms[0] eq 'date_8');
@apms = $doc->element('d8')->def()->applied_macros();
ok($apms[0] eq 'date_8');

ok($doc->element('d8')->applied_macros() == 1);

ok( $doc->element('d8')->applied_macros ( 'date_8' ));
ok(!$doc->element('d8')->applied_macros ( 'integer' ));

$doc->element('d8')->set('20001122');
ok($doc->element('d8')->get() eq '20001122');
# too short, too long, non-digits
eval { $doc->element('d8')->set('2000112') };
ok( $@ );
eval { $doc->element('d8')->set('200011222') };
ok( $@ );
eval { $doc->element('d8')->set('2000112a') };
ok( $@ );
# invalid date (according to calendar-checking)
eval { $doc->element('d8')->set('20001322') };
ok( $@ );
eval { $doc->element('d8')->set('20000931') };
ok( $@ );
ok($doc->element('d8')->set('16000229'));
eval { $doc->element('d8')->set('17000229') };
ok( $@ );

## unix_time
ok($doc->element('ut')->applied_macros ( 'unix_time' ));
$doc->element('ut')->set('975712009');
ok($doc->element('ut')->get() eq '975712009');
eval { $doc->element('ut')->set('975a') };
ok( $@ );

## one_to_ten
ok($doc->element('ot')->applied_macros ( 'range', 'integer' ));
ok($doc->element('ot')->applied_macros ( 'range' ));
ok($doc->element('ot')->applied_macros ( 'integer' ));
ok($doc->element('ot')->applied_macros() == 2);
ok(!$doc->element('ot')->applied_macros ( 'range', 'date_8' ));


$doc->element('ot')->set(1);
$doc->element('ot')->set(9);
$doc->element('ot')->set(10);
ok($doc->element('ot')->get() == 10);
eval { $doc->element('ot')->set('15') }; 
ok( $@ );
eval { $doc->element('ot')->set('2.4') };
ok( $@ );
ok($doc->element('ot')->range_low() == 1);
ok($doc->element('ot')->range_high() == 10);
# now test to make sure we can do a 'method' call from the def, too.
ok($doc->element('ot')->def()->method('range_low') == 1);
ok($doc->element('ot')->def()->range_low() == 1);

## enum
ok( $doc->element('en')->set('foo'));
ok( $doc->element('en')->get() eq 'foo');
ok( $doc->element('en')->set('kazzam'));
ok( $doc->element('en')->get() eq 'kazzam');
ok( $doc->element('en')->set('bar'));
ok( $doc->element('en')->get() eq 'bar');
eval { $doc->element('en')->set('15') };
ok( $@ );
my @choices = $doc->element('en')->enum_options();
#dbg 'choices', join ( "--", sort @choices );
ok('foo--bar--kazzam' eq join ( "--", @choices ));

eval { $doc->element('en')->set('') };
ok( $@ );

ok( $doc->element('en_with_default')->get()  eq  'foo' );
ok( $doc->element('en_with_default')->set('foo') );
ok( $doc->element('en_with_default')->set('kazzam') );
ok( $doc->element('en_with_default')->set('bar') );
ok( $doc->element('en_with_default')->get() eq 'bar' );
$doc->element('en_with_default')->set();
ok($doc->element('en_with_default')->get()  eq  'foo' );
eval { $doc->element('en')->set('15') }; 
ok( $@ );

ok( $doc->element('en_with_empty')->set('foo') );
ok( $doc->element('en_with_empty')->get()  eq  'foo' );
$doc->element('en_with_empty')->set('');
ok( $doc->element('en_with_empty')->get()  eq  '' );

## arbritrary content set hook
$doc->element('capitalized')->set('Hello');
ok("set hook didn't die on us");
eval { $doc->element('capitalized')->set('hello') };
ok( $@ );

## unparseable content in element
eval { $doc->element('sing')->set( "& that's simple" ); };
ok( $@ );

## arg'ed escape
$doc->element('sing')->set ( "& that's simple", escape=>1 );
ok("escaped set hook didn't die on us");
ok( $doc->element('sing')->get() eq "&amp; that's simple" );
ok( $doc->element('sing')->get(unescape=>1) eq "& that's simple" );

# escape configs
$doc->all_basic_escaped ( "<foo>" );
ok($doc->element('all_basic_escaped')->get_without_default() eq '&lt;foo&gt;');
ok($doc->element('all_basic_escaped')->get(unescape=>0) eq 
'&lt;foo&gt;');
ok($doc->element('all_basic_escaped')->get() eq '<foo>');
ok($doc->element('all_basic_escaped')->get(unescape=>1) eq '<foo>');

eval { $doc->all_basic_escaped ( "<foo>", escape => 0 ); };
ok($@ and $@ =~ /BAD_CONTENT/);
$doc->all_basic_escaped ( "<foo>", escape => 1 );
ok($doc->element('all_basic_escaped')->get(unescape=>0) eq '&lt;foo&gt;');

$doc->esc_basic_escaped ( "<foo>" );
ok($doc->element('esc_basic_escaped')->get() eq '&lt;foo&gt;');
ok($doc->element('esc_basic_escaped')->get(unescape=>0) eq '&lt;foo&gt;');
ok($doc->element('esc_basic_escaped')->get(unescape=>1) eq '<foo>');

$doc->unesc_basic_escaped ( "&lt;foo&gt;" );
ok($doc->element('unesc_basic_escaped')->get() eq '<foo>');
ok($doc->element('unesc_basic_escaped')->get(unescape=>0) eq '&lt;foo&gt;');
ok($doc->element('unesc_basic_escaped')->get(unescape=>1) eq '<foo>');

$doc->all_specify_escaped ( "X hello X" );
ok($doc->element('all_specify_escaped')->get(unescape=>0) eq '--x-- hello --x--');
ok($doc->element('all_specify_escaped')->get() eq 'X hello X');

## structure validate hook
$doc->element('sing')->set( "innocuous" );
ok("didn't die setting something innocuous");
$doc->element('sing')->set( "un-typical test" );
eval { $doc->validate(); };
ok( $@ );

my $d2 = XML::Comma::Doc->new ( type=>'_test_validation' );
# should fail because of zero_field (and plu and nested, and nested_sing inside nested)
eval { $doc->validate(); };
ok($@);
$d2->element('zero_field')->set('a true value');
# should fail because of plu (and nested, and nested_sing inside it)
eval { $doc->validate(); };
ok($@);
$d2->element('plu')->set('foo');
# should fail because of nested (and nested_sing inside it)
eval { $doc->validate(); };
ok($@);
$d2->element('nested');
# should fail because of nested_sing inside nested
eval { $doc->validate(); };
ok($@);
$d2->element('nested')->element('nested_sing')->set('foo');
eval { $doc->validate(); };
ok( $@ );

# default value
ok($doc->element('with_default')->get eq 'default stuff');
$doc->element('with_default')->set ( 'something different' );
ok($doc->element('with_default')->get eq 'something different');
# and the empty string, too?
$doc->element('with_default')->set ( '' );
ok($doc->element('with_default')->get eq '');
# and re-undef to get back where we started;
$doc->element('with_default')->set ( undef );
ok($doc->element('with_default')->get eq 'default stuff');

# hash test -- take a few hashes, while changing one of the elements,
# and make sure they match or not as expected
$doc->element('sing')->set ( 'hash test value 1' );
ok( my $hash1 = $doc->comma_hash() );
ok( my $hash2 = $doc->comma_hash() );
$doc->element('sing')->set ( 'hash test value 2' );
ok( my $hash3 = $doc->comma_hash() );
$doc->element('sing')->set ( 'hash test value 1' );
ok( my $hash4 = $doc->comma_hash() );
ok( $hash1 eq $hash2 );
ok( $hash1 ne $hash3 );
ok( $hash1 eq $hash4 );
# now change the one that the hash isn't supposed to take into account
$doc->element('not_hashificated')->set ( 'not hashed test value 1' );
ok( my $hash5 = $doc->comma_hash() );
ok( $hash5 eq $hash4 );

# check is_required
ok($doc->element_is_required ( 'plu' ));
ok($doc->element_is_required ( 'nested' ));
ok(! $doc->element_is_required ( 'with_default' ));

# boolean macro
ok($doc->bool() == 0); # default 0

$doc->element('bool')->toggle;
ok($doc->bool() == 1);
$doc->element('bool')->toggle;
ok($doc->bool() == 0);

$doc->bool ( 1 );
ok($doc->bool() == 1);
$doc->bool ( 'true' );
ok($doc->bool() == 1);
$doc->bool ( 'TRUE' );
ok($doc->bool() == 1);

$doc->bool ( 0 );
ok($doc->bool() == 0 and $doc->bool() eq '0');
$doc->bool ( 'false' );
ok(!$doc->bool());
$doc->bool ( 'FALSE' );
ok(!$doc->bool());

ok($doc->bool_default_true());
$doc->bool_default_true ( 'false' );
ok(!$doc->bool_default_true());
$doc->bool_default_true ( 1 );
ok($doc->bool_default_true());

my $long_to_truncate = "abcdefghijklmnop";
$doc->truncated ( $long_to_truncate );
ok($doc->truncated() eq 'abcdefg');
my $short_to_truncate = "abc";
$doc->truncated ( $short_to_truncate );
ok($doc->truncated() eq 'abc');

#make sure the doc validates when a required element is set to 0
# or a true value and not when set to the empty string
$doc->element('zero_field')->set(0);
eval { $doc->validate() };
ok(!$@);
$doc->zero_field('');
eval { $doc->validate() };
ok($@);
$doc->zero_field('abc');
eval { $doc->validate() };
ok(!$@);

