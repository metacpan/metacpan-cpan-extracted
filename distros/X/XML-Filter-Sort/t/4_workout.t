# $Id: 4_workout.t,v 1.3 2005/04/20 20:03:53 grantm Exp $

use strict;
use Test::More;

BEGIN { # Seems to be required by older Perls

  unless(eval { require XML::SAX::Writer }) {
    plan skip_all => 'XML::SAX::Writer not installed';
  }

  unless(eval { require XML::SAX::ParserFactory }) {
    plan skip_all => 'XML::SAX::ParserFactory not installed';
  }

  unless(eval { require XML::SAX::Machines }) {
    plan skip_all => 'XML::SAX::Machines not installed';
  }

}

plan tests => 26;

use XML::Filter::Sort;
use XML::SAX::Machines qw( :all );

$^W = 1;

my(@opts, $xmlin, $xmlout, $sorter);


##############################################################################
# Global used to flag disk rather than memory buffering
#

@main::TempOpts = () unless(@main::TempOpts);


##############################################################################
# Sort using full text content as key (including leading digits)
#

$xmlin = q(<list>
  <person>1<firstname>Zebedee</firstname></person>
  <person>2<firstname>Yorick</firstname></person>
  <person>3<firstname>Wayne</firstname></person>
  <person>4<firstname>Xavier</firstname></person>
</list>);

$xmlout = '';

@opts = (Record => 'person');
push @opts, @main::TempOpts;

$sorter = Pipeline(
  XML::Filter::Sort->new(@opts) => \$xmlout
);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, $xmlin, 'Default key to full text content, alpha, asc');


##############################################################################
# Sort using text content of specified child element as a key
#

$xmlout = '';

@opts = (
  Record => 'person',
  Keys   => 'firstname',
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<list>
  <person>3<firstname>Wayne</firstname></person>
  <person>4<firstname>Xavier</firstname></person>
  <person>2<firstname>Yorick</firstname></person>
  <person>1<firstname>Zebedee</firstname></person>
</list>), 'Parsed key from string and extracted element content');


##############################################################################
# Check that a 'foreign' element in the middle of a sequence of records 
# causes the records before and the records after to be sorted as two 
# independent lists.
#

$xmlin = q(<list>
  <person>1<firstname>Zebedee</firstname></person>
  <person>2<firstname>Yorick</firstname></person>
  <snackfood>popcorn</snackfood>
  <person>3<firstname>Wayne</firstname></person>
  <person>4<firstname>Xavier</firstname></person>
  <trailer>0</trailer>
</list>);

$xmlout = '';

@opts = (
  Record => 'person',
  Keys   => 'firstname',
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<list>
  <person>2<firstname>Yorick</firstname></person>
  <person>1<firstname>Zebedee</firstname></person>
  <snackfood>popcorn</snackfood>
  <person>3<firstname>Wayne</firstname></person>
  <person>4<firstname>Xavier</firstname></person>
  <trailer>0</trailer>
</list>), 'Sorted two independent lists (element between)');


##############################################################################
# Check that non-whitespace text causes the same effect.
#

$xmlin = q(<list>
  <person>1<firstname>Zebedee</firstname></person>
  <person>2<firstname>Yorick</firstname></person>
  popcorn
  <person>3<firstname>Wayne</firstname></person>
  <person>4<firstname>Xavier</firstname></person>
</list>);

$xmlout = '';

@opts = (
  Record => 'person',
  Keys   => 'firstname',
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<list>
  <person>2<firstname>Yorick</firstname></person>
  <person>1<firstname>Zebedee</firstname></person>
  popcorn
  <person>3<firstname>Wayne</firstname></person>
  <person>4<firstname>Xavier</firstname></person>
</list>), 'Sorted two independent lists (text between - easy case)');


##############################################################################
# Repeat that last test with slightly different input data to expose a flaw
# which probably ought to be fixed.
#

$xmlin = q(<list>
  <person>1<firstname>Zebedee</firstname></person>
  <person>2<firstname>Yorick</firstname></person>
  popcorn
  <person>4<firstname>Xavier</firstname></person>
  <person>3<firstname>Wayne</firstname></person>
</list>);

$xmlout = '';

@opts = (
  Record => 'person',
  Keys   => 'firstname',
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

TODO: { local $TODO = 'Trailing whitespace on leading text not quite done';
is($xmlout, q(<list>
  <person>2<firstname>Yorick</firstname></person>
  <person>1<firstname>Zebedee</firstname></person>
  popcorn
  <person>3<firstname>Wayne</firstname></person>
  <person>4<firstname>Xavier</firstname></person>
</list>), 'Sorted two independent lists (text between - pathological case)');
}


##############################################################################
# Now do a similar test with a comment separating the two record lists.
#

$xmlin = q(<list>
  <person>1<firstname>Zebedee</firstname></person>
  <person>2<firstname>Yorick</firstname></person>
  <!-- popcorn -->
  <person>4<firstname>Xavier</firstname></person>
  <person>3<firstname>Wayne</firstname></person>
</list>);

$xmlout = '';

@opts = (
  Record => 'person',
  Keys   => 'firstname',
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<list>
  <person>2<firstname>Yorick</firstname></person>
  <person>1<firstname>Zebedee</firstname></person>
  <!-- popcorn -->
  <person>3<firstname>Wayne</firstname></person>
  <person>4<firstname>Xavier</firstname></person>
</list>), 'Sorted two independent lists (comment between)');


##############################################################################
# Same again but with a processing instruction separating the two record lists.
#

$xmlin = q(<list>
  <person>1<firstname>Zebedee</firstname></person>
  <person>2<firstname>Yorick</firstname></person>
  <?snackfood what='popcorn'?>
  <person>4<firstname>Xavier</firstname></person>
  <person>3<firstname>Wayne</firstname></person>
</list>);

$xmlout = '';

@opts = (
  Record => 'person',
  Keys   => 'firstname',
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<list>
  <person>2<firstname>Yorick</firstname></person>
  <person>1<firstname>Zebedee</firstname></person>
  <?snackfood what='popcorn'?>
  <person>3<firstname>Wayne</firstname></person>
  <person>4<firstname>Xavier</firstname></person>
</list>), 'Sorted two independent lists (PI between)');


##############################################################################
# Check that as each record is buffered, reordered and spat back out, it
# retains its own leading whitespace.
#

$xmlin = q(<list>
        <person><firstname>Zebedee</firstname></person>
      <person><firstname>Yorick</firstname></person>
  <person><firstname>Wayne</firstname></person>
    <person><firstname>Xavier</firstname></person>
</list>);

$xmlout = '';

@opts = (
  Record => 'person',
  Keys   => 'firstname',
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<list>
  <person><firstname>Wayne</firstname></person>
    <person><firstname>Xavier</firstname></person>
      <person><firstname>Yorick</firstname></person>
        <person><firstname>Zebedee</firstname></person>
</list>), 'Funky indentation preserved');


##############################################################################
# Throw a namespace definition into the mix and confirm it is ignored.
#

$xmlin = q(<list xmlns:bob='bob.com'>
  <person>1<firstname>Zebedee</firstname></person>
  <bob:person>2<firstname>Yorick</firstname></bob:person>
  <person>3<firstname>Wayne</firstname></person>
  <person>4<firstname>Xavier</firstname></person>
</list>);

$xmlout = '';

@opts = (
  Record => 'person',
  Keys   => 'firstname',
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<list xmlns:bob='bob.com'>
  <person>3<firstname>Wayne</firstname></person>
  <person>4<firstname>Xavier</firstname></person>
  <bob:person>2<firstname>Yorick</firstname></bob:person>
  <person>1<firstname>Zebedee</firstname></person>
</list>), 'Record selection with optional namespace works');


##############################################################################
# Now sort only the records with no namespace
#

$xmlin = q(<list xmlns:bob='bob.com'>
  <bob:person>1<firstname>Zebedee</firstname></bob:person>
  <person>2<firstname>Yorick</firstname></person>
  <person>3<firstname>Wayne</firstname></person>
  <person xmlns='kate.com'>4<firstname>Xavier</firstname></person>
  <person>5<firstname>Vernon</firstname></person>
  <person>6<firstname>Trevor</firstname></person>
  <person>7<firstname>Ulbrecht</firstname></person>
</list>);

$xmlout = '';

@opts = (
  Record => '{}person',
  Keys   => 'firstname',
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<list xmlns:bob='bob.com'>
  <bob:person>1<firstname>Zebedee</firstname></bob:person>
  <person>3<firstname>Wayne</firstname></person>
  <person>2<firstname>Yorick</firstname></person>
  <person xmlns='kate.com'>4<firstname>Xavier</firstname></person>
  <person>6<firstname>Trevor</firstname></person>
  <person>7<firstname>Ulbrecht</firstname></person>
  <person>5<firstname>Vernon</firstname></person>
</list>), 'Record selection with no namespace works');


##############################################################################
# Now sort only the records with specified namespace
#

$xmlin = q(<list xmlns:bob='bob.com'>
  <bob:person>1<firstname>Zebedee</firstname></bob:person>
  <bob:person>2<firstname>Yorick</firstname></bob:person>
  <bob:person>3<firstname>Wayne</firstname></bob:person>
  <person>4<firstname>Xavier</firstname></person>
  <person>5<firstname>Vernon</firstname></person>
  <person>6<firstname>Trevor</firstname></person>
  <person>7<firstname>Ulbrecht</firstname></person>
</list>);

$xmlout = '';

@opts = (
  Record => '{bob.com}person',
  Keys   => 'firstname',
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<list xmlns:bob='bob.com'>
  <bob:person>3<firstname>Wayne</firstname></bob:person>
  <bob:person>2<firstname>Yorick</firstname></bob:person>
  <bob:person>1<firstname>Zebedee</firstname></bob:person>
  <person>4<firstname>Xavier</firstname></person>
  <person>5<firstname>Vernon</firstname></person>
  <person>6<firstname>Trevor</firstname></person>
  <person>7<firstname>Ulbrecht</firstname></person>
</list>), 'Record selection with specific namespace works');


##############################################################################
# Put some comments into the mix and confirm they are handled correctly.
#

$xmlin = q(<list>
  <person>
    <!-- three -->
    <firstname>Zebedee</firstname>
  </person>
  <person>
    <!-- one -->
    <firstname>Xavier</firstname>
  </person>
  <person>
    <!-- two -->
    <firstname>Yorick</firstname>
  </person>
</list>);

$xmlout = '';


@opts = (
  Record => 'person',
  Keys   => 'firstname',
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<list>
  <person>
    <!-- one -->
    <firstname>Xavier</firstname>
  </person>
  <person>
    <!-- two -->
    <firstname>Yorick</firstname>
  </person>
  <person>
    <!-- three -->
    <firstname>Zebedee</firstname>
  </person>
</list>), 'Buffering of comments works');


##############################################################################
# Do the same with processing instructions.
#

$xmlin = q(<list>
  <person>
    <?pagebreak three?>
    <firstname>Zebedee</firstname>
  </person>
  <person>
    <?pagebreak one?>
    <firstname>Xavier</firstname>
  </person>
  <person>
    <?pagebreak two?>
    <firstname>Yorick</firstname>
  </person>
</list>);

$xmlout = '';


@opts = (
  Record => 'person',
  Keys   => 'firstname',
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<list>
  <person>
    <?pagebreak one?>
    <firstname>Xavier</firstname>
  </person>
  <person>
    <?pagebreak two?>
    <firstname>Yorick</firstname>
  </person>
  <person>
    <?pagebreak three?>
    <firstname>Zebedee</firstname>
  </person>
</list>), 'Buffering of PIs works');


##############################################################################
# Run a multi-key sort - two alpha keys.
#

$xmlin = q(<directory>
  <title>This is a list of names &amp; ages</title>
  <person age='35'>
    <firstname>Zebedee</firstname>
    <lastname>Boozle</lastname>
  </person>
  <person age='4'>
    <firstname>Yorick</firstname>
    <lastname>Cabbage</lastname>
  </person>
  <person age='39'>
    <firstname>Yorick</firstname>
    <lastname>Cabbage</lastname>
  </person>
  <person age='19'>
    <firstname>Xavier</firstname>
    <lastname>Aardvark</lastname>
  </person>
  <footer>The End!</footer>
</directory>);

$xmlout = '';

@opts = (
  Record => 'person',
  Keys   => '
	      lastname
	      firstname
	      @age
	    ',
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<directory>
  <title>This is a list of names &amp; ages</title>
  <person age='19'>
    <firstname>Xavier</firstname>
    <lastname>Aardvark</lastname>
  </person>
  <person age='35'>
    <firstname>Zebedee</firstname>
    <lastname>Boozle</lastname>
  </person>
  <person age='39'>
    <firstname>Yorick</firstname>
    <lastname>Cabbage</lastname>
  </person>
  <person age='4'>
    <firstname>Yorick</firstname>
    <lastname>Cabbage</lastname>
  </person>
  <footer>The End!</footer>
</directory>), 'Multi-element records and multi-key sort OK');


##############################################################################
# Introduce a third sort key - numeric.
#

$xmlout = '';

@opts = (
  Record => 'person',
  Keys   => '
	      lastname,  alpha, asc
	      firstname, alpha, asc
	      @age,      num,   asc
	    ',
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<directory>
  <title>This is a list of names &amp; ages</title>
  <person age='19'>
    <firstname>Xavier</firstname>
    <lastname>Aardvark</lastname>
  </person>
  <person age='35'>
    <firstname>Zebedee</firstname>
    <lastname>Boozle</lastname>
  </person>
  <person age='4'>
    <firstname>Yorick</firstname>
    <lastname>Cabbage</lastname>
  </person>
  <person age='39'>
    <firstname>Yorick</firstname>
    <lastname>Cabbage</lastname>
  </person>
  <footer>The End!</footer>
</directory>), 'Numeric sort key OK');


##############################################################################
# Check that descending order works for both alpha and numeric sorts
#

$xmlout = '';

@opts = (
  Record => 'person',
  Keys   => '
	      firstname, alpha, desc
	      lastname,  alpha, asc
	      @age,      num,   desc
	    ',
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<directory>
  <title>This is a list of names &amp; ages</title>
  <person age='35'>
    <firstname>Zebedee</firstname>
    <lastname>Boozle</lastname>
  </person>
  <person age='39'>
    <firstname>Yorick</firstname>
    <lastname>Cabbage</lastname>
  </person>
  <person age='4'>
    <firstname>Yorick</firstname>
    <lastname>Cabbage</lastname>
  </person>
  <person age='19'>
    <firstname>Xavier</firstname>
    <lastname>Aardvark</lastname>
  </person>
  <footer>The End!</footer>
</directory>), 'Descending order OK');


##############################################################################
# Use a code reference rather than alpha or numeric comparator
#

$xmlin = q(<list>
  <part>QX54763</part>
  <part>AS87645</part>
  <part>YT19895</part>
  <part>RS04198</part>
</list>);

$xmlout = '';

@opts = (
  Record => 'part',
  Keys   => [ 
	      [ '.' => sub {
			      my @nums = map { /(\d+)/ } @_;
			      $nums[0] <=> $nums[1];
			    } ]
	    ]
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<list>
  <part>RS04198</part>
  <part>YT19895</part>
  <part>QX54763</part>
  <part>AS87645</part>
</list>), 'Coderef comparator OK');


##############################################################################
# Test that by default case of keys is significant
#

$xmlin = q(<options>
  <colour>red</colour>
  <colour>Green</colour>
  <colour>blue</colour>
</options>);

$xmlout = '';

@opts = (
  Record => 'colour',
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<options>
  <colour>Green</colour>
  <colour>blue</colour>
  <colour>red</colour>
</options>), 'Case is significant by default');


##############################################################################
# But the IgnoreCase option fixes that
#

$xmlout = '';

@opts = (
  Record => 'colour',
  IgnoreCase => 1,
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<options>
  <colour>blue</colour>
  <colour>Green</colour>
  <colour>red</colour>
</options>), 'IgnoreCase makes case insignificant');


##############################################################################
# Test that by default space in keys is significant
#

$xmlin = q(<options>
  <colour id='7'> red</colour>
  <colour id='2'>green</colour>
  <colour id='1'>  blue</colour>
  <colour id='3'> light blue</colour>
  <colour id='4'>light  blue</colour>
  <colour id='5'> light    blue  </colour>
  <colour id='6'> light    blue</colour>
</options>);

$xmlout = '';

@opts = (
  Record => 'colour',
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<options>
  <colour id='1'>  blue</colour>
  <colour id='6'> light    blue</colour>
  <colour id='5'> light    blue  </colour>
  <colour id='3'> light blue</colour>
  <colour id='7'> red</colour>
  <colour id='2'>green</colour>
  <colour id='4'>light  blue</colour>
</options>), 'Space is significant by default');


##############################################################################
# But the NormaliseKeySpace option fixes that
#

$xmlout = '';

@opts = (
  Record => 'colour',
  NormaliseKeySpace => 1,
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<options>
  <colour id='1'>  blue</colour>
  <colour id='2'>green</colour>
  <colour id='3'> light blue</colour>
  <colour id='4'>light  blue</colour>
  <colour id='5'> light    blue  </colour>
  <colour id='6'> light    blue</colour>
  <colour id='7'> red</colour>
</options>), 'NormaliseKeySpace makes spaces insignificant');


##############################################################################
# And it fixes it for Americanz too
#

$xmlout = '';

$xmlin = q(<options>
  <color id='7'> red</color>
  <color id='2'>green</color>
  <color id='1'>  blue</color>
  <color id='3'> light blue</color>
  <color id='4'>light  blue</color>
  <color id='5'> light    blue  </color>
  <color id='6'> light    blue</color>
</options>);

$xmlout = '';

@opts = (
  Record => 'color',
  NormalizeKeySpace => 1,
  #      ^======= this is the bit we're testing
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<options>
  <color id='1'>  blue</color>
  <color id='2'>green</color>
  <color id='3'> light blue</color>
  <color id='4'>light  blue</color>
  <color id='5'> light    blue  </color>
  <color id='6'> light    blue</color>
  <color id='7'> red</color>
</options>), 'And it works for Americanz too');


##############################################################################
# Now try out the KeyFilterSub option.
#

$xmlout = '';

$xmlin = q(<options>
  <color>red</color>
  <color>green</color>
  <color>orange</color>
  <color>pink</color>
  <color>blue</color>
</options>);

$xmlout = '';

@opts = (
  Record => 'color',
  KeyFilterSub => sub { map { scalar reverse($_) } @_; },
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<options>
  <color>red</color>
  <color>orange</color>
  <color>blue</color>
  <color>pink</color>
  <color>green</color>
</options>), 'KeyFilterSub does its job');


##############################################################################
# Now try IgnoreCase, NormaliseKeySpace and KeyFilterSub simultaneously (and
# at the same time).
#

$xmlout = '';

$xmlin = q(<options>
  <color id='1'>RED</color>
  <color id='2'>green</color>
  <color id='3'> light blue </color>
  <color id='4'>  LIGHT  BLUE  </color>
  <color id='5'>orange</color>
  <color id='6'>PINK</color>
  <color id='7'>blue</color>
</options>);

$xmlout = '';

@opts = (
  Record => 'color',
  NormaliseKeySpace => 1,
  IgnoreCase => 1,
  KeyFilterSub => sub { map { scalar reverse($_) } @_; },
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<options>
  <color id='1'>RED</color>
  <color id='5'>orange</color>
  <color id='7'>blue</color>
  <color id='3'> light blue </color>
  <color id='4'>  LIGHT  BLUE  </color>
  <color id='6'>PINK</color>
  <color id='2'>green</color>
</options>), 'IgnoreCase, NormaliseKeySpace & KeyFilterSub play nicely');


##############################################################################
# Slightly unusual version of KeyFilterSub which combine multiple keys
# into one.
#

$xmlout = '';

$xmlin = q(<options>
  <color prime='2'>red</color>
  <color prime='23'>green</color>
  <color prime='5'>orange</color>
  <color prime='7'>BLUE</color>
  <color prime='4'>RED</color>
  <color prime='23'>Green</color>
  <color prime='23'>orange</color>
  <color prime='19'>blue</color>
</options>);

$xmlout = '';

@opts = (
  Record => 'color',
  Keys => '@prime, asc, desc; .', 
  IgnoreCase => 1,
  KeyFilterSub => sub { sprintf("%02u%s", @_); },
);
push @opts, @main::TempOpts;

$sorter = Pipeline(XML::Filter::Sort->new(@opts) => \$xmlout);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<options>
  <color prime='23'>orange</color>
  <color prime='23'>green</color>
  <color prime='23'>Green</color>
  <color prime='19'>blue</color>
  <color prime='7'>BLUE</color>
  <color prime='5'>orange</color>
  <color prime='4'>RED</color>
  <color prime='2'>red</color>
</options>), 'Synthetic key generation via KeyFilterSub');


##############################################################################
# Test that text content of '0' doesn't give us grief (any more).
#

$xmlin = q(<list>
  <prefix>0</prefix>
  <item>9</item>
  <item>5</item>
  <item>0</item>
  <item>7</item>
  <suffix>0</suffix>
</list>);

$xmlout = '';

@opts = (Record => 'item', Keys => '., num, asc');
push @opts, @main::TempOpts;

$sorter = Pipeline(
  XML::Filter::Sort->new(@opts) => \$xmlout
);
$sorter->parse_string($xmlin);
fix_xml($xmlout);

is($xmlout, q(<list>
  <prefix>0</prefix>
  <item>0</item>
  <item>5</item>
  <item>7</item>
  <item>9</item>
  <suffix>0</suffix>
</list>), 'No problem with text content of "0" even in sort key');



##############################################################################
#                       S U B R O U T I N E S
##############################################################################

##############################################################################
# Sometimes the output from the SAX pipeline may not be exactly what we're
# expecting - for benign reasons.  This routine strips the initial XML
# declaration which gets added by LibXML but not by other parsers.  It also
# changes attribute double quotes to single.
#

sub fix_xml {
  $_[0] =~ s{^<\?xml\s.*?\?>\s*}{}s;
  $_[0] =~ s{(\w+)="([^>]*?)"}{$1='$2'}sg;
}
