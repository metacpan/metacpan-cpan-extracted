# $Id: 3_sort.t,v 1.1.1.1 2002/06/14 20:39:53 grantm Exp $

use strict;
use Test::More;

BEGIN { # Seems to be required by older Perls

  unless(eval { require XML::SAX::Writer }) {
    plan skip_all => 'XML::SAX::Writer not installed';
  }

  unless(eval { require XML::SAX::ParserFactory }) {
    plan skip_all => 'XML::SAX::ParserFactory not installed';
  }

}

plan tests => 9;

$^W = 1;

##############################################################################
# Confirm that the module compiles
#

use XML::Filter::Sort;

ok(1, 'XML::Filter::Sort compiled OK');


##############################################################################
# Try creating a Sort object and test that it fails when 'Record' option is
# omitted.
#

my($sorter);
eval { $sorter = XML::Filter::Sort->new() };

like($@, qr{You must set the 'Record' option}, "Can't omit 'Record' option");


##############################################################################
# Try again, this time supplying required 'Record' option as well as a handler
# object.  Confirm that object was created and default value for 'Keys' was
# used.
#

my $xml = '';
my $writer = XML::SAX::Writer->new(Output => \$xml);

$sorter = XML::Filter::Sort->new(Record => 'rec', Handler => $writer);

ok(ref($sorter), 'Created a sort filter object');
isa_ok($sorter, 'XML::Filter::Sort');

is_deeply($sorter->{Keys}, [ [ '.', 'alpha', 'asc' ] ],
          'Default value for sort keys OK');


##############################################################################
# Poke some SAX events into it and confirm it doesn't die
#

my $list_elem = {
  Name         => 'list',
  LocalName    => 'list',
  Prefix       => '',
  NamespaceURI => '',
  Attributes   => {},
};

my $rec_elem = {
  Name         => 'rec',
  LocalName    => 'rec',
  Prefix       => '',
  NamespaceURI => '',
  Attributes   => {},
};

$sorter->start_document();
$sorter->start_element($list_elem);
foreach my $text (qw(Tom Dick Larry)) {
  $sorter->start_element($rec_elem);
  $sorter->characters({ Data => $text});
  $sorter->end_element($rec_elem);
}
$sorter->end_element($list_elem);
$sorter->end_document();

ok(1, 'Filtered a document without crashing');


##############################################################################
# Confirm that the output was actually sorted
#

is($xml, '<list><rec>Dick</rec><rec>Larry</rec><rec>Tom</rec></list>',
   'Records sorted correctly');


##############################################################################
# Create another object and confirm that non-default 'Keys' value is
# accepted.
#

my $keys = [
  [ 'firstname', 'alpha', 'asc'  ],
  [ 'lastname',  'alpha', 'asc'  ],
  [ 'age',       'num',   'desc' ],
];

$sorter = XML::Filter::Sort->new(
  Record => 'rec', Handler => $writer, Keys => $keys
);

is_deeply($sorter->{Keys}, $keys, 'Multi-key array looks OK');


##############################################################################
# Do it again, but this time specify 'Keys' using a scalar rather than nested
# arrays.
#

$sorter = XML::Filter::Sort->new(
  Record => 'rec', Handler => $writer,
  Keys => "
	    firstname
	    lastname
	    age num desc
          "
);

is_deeply($sorter->{Keys}, $keys, 'Multi-key array from scalar looks OK');


##############################################################################
# More complex tests of the sorting functionality are deferred to the next
# script which requires XML::SAX::Machines (which is surely installed if this
# punter is serious).
#

