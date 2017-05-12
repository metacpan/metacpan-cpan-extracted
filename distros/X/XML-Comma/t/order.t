use strict;

#TODO: convert test::more numbers to useful strings
use Test::More 'no_plan';

use lib ".test/lib/";

use XML::Comma;
use XML::Comma::Util qw( dbg );

my $doc_block = <<END;
<_test_order>
  <a>0</a>
  <b>1</b>
  <a>2</a>
  <b>3</b>
  <a>4</a>
  <b>5</b>
</_test_order>
END

###########

my $def = XML::Comma::Def->read ( name => '_test_order' );
ok($def);

## create the doc (which tests permitting plural creation)
my $doc = XML::Comma::Doc->new ( block=>$doc_block );
ok($doc);

my @elements = $doc->elements ( 'a', 'b' );
ok(scalar(@elements) == 6);

for ( my $i=0; $i < scalar(@elements); $i++ ) {
  if ( ! $elements[$i]->get() == $i ) {
    die "did not match\n";
  }
}
ok("didn't die");

$doc->group_elements();
ok("didn't die");

@elements = $doc->elements ( 'a', 'b' );
ok($elements[0]->get()  == 0);
ok($elements[1]->get()  == 2);
ok($elements[2]->get()  == 4);
ok($elements[3]->get()  == 1);
ok($elements[4]->get()  == 3);
ok($elements[5]->get()  == 5);


my @sorted_as = $doc->sort_elements('a');
ok($sorted_as[0]->get() == 4);
ok($sorted_as[1]->get() == 2);
ok($sorted_as[2]->get() == 0);
ok(!$sorted_as[3]);

my @as_again = $doc->elements('a');
ok($as_again[0]->get() == 4);
ok($as_again[1]->get() == 2);
ok($as_again[2]->get() == 0);
ok(!$as_again[3]);

@elements = $doc->elements();
ok($elements[0]->get()  == 4);
ok($elements[1]->get()  == 2);
ok($elements[2]->get()  == 0);
ok($elements[3]->get()  == 1);
ok($elements[4]->get()  == 3);
ok($elements[5]->get()  == 5);
ok(!$elements[6]);

@elements = $doc->sort_elements();
ok($elements[0]->get()  == 5);
ok($elements[1]->get()  == 4);
ok($elements[2]->get()  == 3);
ok($elements[3]->get()  == 2);
ok($elements[4]->get()  == 1);
ok($elements[5]->get()  == 0);
ok(!$elements[6]);

@elements = $doc->elements();
ok($elements[0]->get()  == 5);
ok($elements[1]->get()  == 4);
ok($elements[2]->get()  == 3);
ok($elements[3]->get()  == 2);
ok($elements[4]->get()  == 1);
ok($elements[5]->get()  == 0);
ok(!$elements[6]);

$doc->add_element('ranked')->rank(0);
$doc->add_element('ranked')->rank(1);
$doc->add_element('ranked')->rank(2);
$doc->add_element('ranked')->rank(3);

@elements = $doc->sort_elements('ranked');
ok($elements[0]->rank()  == 3);
ok($elements[1]->rank()  == 2);
ok($elements[2]->rank()  == 1);
ok($elements[3]->rank()  == 0);
ok(!$elements[4]);

@elements = $doc->elements('ranked');
ok($elements[0]->rank()  == 3);
ok($elements[1]->rank()  == 2);
ok($elements[2]->rank()  == 1);
ok($elements[3]->rank()  == 0);
ok(!$elements[4]);

