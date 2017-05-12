use strict;

use Test::More 'no_plan';

use lib ".test/lib/";

use XML::Comma;
use XML::Comma::Util qw( dbg );

my $doc_block = <<END;
<_test_virtual_element>
  <first>foo</first>
  <second>bar</second>
</_test_virtual_element>
END

###########

## make def
my $def = XML::Comma::Def->read ( name=>'_test_virtual_element' );
XML::Comma::DefManager->add_def ( $def );
ok($def);

## create the doc
my $doc = XML::Comma::Doc->new ( block=>$doc_block );
ok($doc);

## what are the defined methods?
ok(join ( ',', sort($def->method_names()) ) eq 'both,test_args');

## test our virtual get
ok($doc->method('both') eq 'foobar' and $doc->both() eq 'foobar');

## test our virtual set
ok($doc->test_args("a", "b"));
ok($doc->method('both') eq 'ab');

# test illegal autoload
eval { $doc->sadf(); };
ok( $@ );

# test elements_group_add and elements_group_get
$doc->elements_group_add ( 'plu', '1', '2', '3' );
$doc->elements_group_add ( 'plu', '23', '35', '59' );
ok('1/2/3/23/35/59' eq (join '/', @{$doc->elements_group_get('plu')}));

# test elements_group_delete and elements_group_lists
$doc->elements_group_delete ( 'plu', 1, 3, 35, 59 );
ok('2/23' eq (join '/', @{$doc->elements_group_get('plu')}));
ok($doc->elements_group_lists ( 'plu', 23 ));
ok(! $doc->elements_group_lists ( 'plu', 1 ));

# test elements_group_delete
$doc->elements_group_delete ( 'plu' );
ok(! @{$doc->elements_group_get('plu')});

# test non-nested singular
$doc->element('first')->set('hello');
ok($doc->first() eq 'hello');
$doc->first('goodbye');
ok($doc->first() eq 'goodbye');

# test non-nested plural
$doc->elements_group_add ( 'plu', '1', '2', '3' );
ok('1/2/3' eq (join '/', @{$doc->elements_group_get('plu')}));
ok('1/2/3' eq (join '/', @{$doc->plu()}));
$doc->plu ( '12','19' );
ok('1/2/3/12/19' eq (join '/', @{$doc->plu()}));

# test nested singular
$doc->element('nested_sing')->element('ns_inside')->set('foo');
ok (
    $doc->element('nested_sing')->element('ns_inside')->get() eq
    $doc->nested_sing->element('ns_inside')->get()
   );

# test nested plural
my $nel1 = $doc->element('nested_plu');
my $nel2 = $doc->add_element('nested_plu');
my $nel3 = $doc->add_element('nested_plu');
my @nels = $doc->nested_plu();
ok($nels[0] == $nel1  and  $nels[1] == $nel2  and  $nels[2] == $nel3);

# test delete_element() -- use elements just added
# delete 3
my $deleted = $doc->delete_element('nested_plu');
ok($deleted == 1);
@nels = $doc->nested_plu();
ok($nels[0] == $nel1  and  $nels[1] == $nel2);
# delete 2
$deleted = $doc->delete_element('nested_plu');
ok($deleted == 1);
@nels = $doc->nested_plu();
ok($nels[0] == $nel1);
# delete 1
$deleted = $doc->delete_element('nested_plu');
ok($deleted == 1);
@nels = $doc->nested_plu();
#@nels = $doc->elements('nested_plu');
ok(! @nels);
# delete non-existent
$deleted = $doc->delete_element('nested_plu');
ok(! defined $deleted);

# test elements_group_add_uniq
$doc->elements_group_delete ( 'plu' );
$doc->elements_group_add_uniq ( 'plu', 'a', 'b' );
my ( $a, $b, $c, $d ) = $doc->elements_group_get ( 'plu' );
ok($a eq 'a' and $b eq 'b' and ! defined $c);
$doc->elements_group_add_uniq ( 'plu', 'a', 'b', 'c' );
( $a, $b, $c, $d ) = $doc->elements_group_get ( 'plu' );
ok($a eq 'a' and $b eq 'b' and $c eq 'c' and ! defined $d);

# test set hook
$doc->third ( "foo", value=>'bar' );
ok($doc->third() eq 'bar');
$doc->third ( "something else", value=>'fish' );
ok($doc->third() eq 'fish');

# test def_pnotes
ok($doc->def()->def_pnotes()->{test} eq 'ok');
$doc->def()->def_pnotes()->{foo} = 'bar';
ok($doc->def()->def_pnotes()->{foo} eq 'bar');
ok($doc->element('looks_at_firsts_pnotes')->pn->{first_value} eq 'plop');
ok(XML::Comma->def_pnotes('_test_virtual_element:first')->{first_value} eq 'plop');

# test pnotes
my $doc2 = XML::Comma::Doc->new ( type=>"_test_virtual_element" );
$doc->pnotes->{'foo'} = 'bar';
$doc2->pnotes->{'foo'} = 'other';
ok($doc->pnotes->{'foo'}  eq 'bar');
ok($doc2->pnotes->{'foo'} eq 'other');
