# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use strict;
use Test::More( tests => 75 );
use FindBin qw($Bin);
use lib "$Bin/../blib/lib";  # Use the copy of the module in the build library
chdir $Bin;
use_ok('Text::TagTemplate');


######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $out;

my $t = new Text::TagTemplate;
isa_ok($t, 'Text::TagTemplate', "Create a new object.");

my $t2 = new Text::TagTemplate( 1 => 2, 3 => 4 );
isa_ok($t2,'Text::TagTemplate',"Create a new object with tags in a hash.");


my $t3 = new Text::TagTemplate( +{ 1 => 2, 3 => 4 } );
isa_ok($t3,'Text::TagTemplate',"Create a new object with tags in a hashref.");


cmp_ok( $t->auto_cap(0),'==',0,"auto_cap() - Set auto_cap to 0");
cmp_ok( $t->auto_cap(1),'==',1,"auto_cap() - Set auto_cap to 1");

cmp_ok($t->unknown_action,'eq','CONFESS',"unknown_action() - Get value.");
cmp_ok($t->unknown_action( 'foo' ),'eq','foo',"unknown_action() - Set value.");

cmp_ok(join( ' ', sort %{ $t2->tags } ),'eq', '1 2 3 4', "tags() - Get tags from object created with hash.");
cmp_ok(join( ' ', sort %{ $t3->tags } ),'eq', '1 2 3 4', "tags() - Get tags from object created with hashref.");
ok($t->tags( 1 => 'one', 2 => 'two', 3 => 'three', 4 => 'four' ), "tags() - Set tags using tags() method." );
cmp_ok(join( ' ', sort keys %{ $t->tags } ),'eq', '1 2 3 4', "tags() - Get tag names we just set.");
cmp_ok(join( ' ', sort values %{ $t->tags } ),'eq', 'four one three two', "tags() - Get tag values we just set.");
ok($t->add_tag( 5 => 6 ), "add_tag() - Add a single tag.");
cmp_ok(join( ' ', sort keys %{ $t->tags } ),'eq', '1 2 3 4 5', "tags() - Get tag names including new tag.");

ok($t->add_tags( 7 => 8, 9 => 'A' ),"add_tags() - with a hash.");
ok($t->add_tags( +{ B => 'C', D => 'E' } ), "add_tags()  - with a hashref.");

my $expected = join( ' ', sort %{ $t->tags } );
is( $expected, '1 2 3 4 5 6 7 8 9 A B C D E four one three two',
    "Check that hashref tags were added.");

ok($t->delete_tag( 1 ), "delete_tag() - Delete one of the tags.");

undef $expected;
$expected = join( ' ', sort %{ $t->tags } );
is( $expected, '2 3 4 5 6 7 8 9 A B C D E four three two',
   "delete_tag() = Check that the tag is really gone.");

ok($t->clear_tags,"clear_tags()");

is( scalar keys(%{ $t->tags }), 0, "clear_tags - Check we cleared them.");

ok( $t->add_list_tag( 'L', +[ 1, 2, 3, 4, 5 ], sub { return +{ N => $_[ 0 ] } } ),
     "add_list_tag()");

undef $expected;
$expected = <<'eos';
L: N: 1
N: 2
N: 3
N: 4
N: 5
eos

$out = $t->parse( 'L: <#L ENTRY_FILE="test-entry.htmlf">' );
is($out,$expected,"parse() - Test the list tag.");



undef $expected;
$expected = '1 2 3 4 5';
ok($t->list( '1', '2', '3', '4', '5' ), "list() - Set the list.");
is(join(' ', $t->list), $expected, "list() - Get the list.");

my $string1 = '1: <#1>, 3: <#3>';
ok($t->template_string($string1), "template_string() - Set template string.");
is($t->template_string,$string1,"template_string() - Get template string.");

$t->tags( 1 => 'TAG ONE', 3 => 'TAG THREE' );
{
 my $expected1 = '1: TAG ONE, 3: TAG THREE';
 my $expected2 = '3: TAG THREE, 1: TAG ONE';
 my $expected3 = '4: four, 5: five';
 my $expected4 = '9: A, B: C';
 is($t->parse, $expected1, "parse() - check parsing template_string.");
 is($t->parse('3: <#3>, 1: <#1>'), $expected2, "parse() - string supplied as argument.");
 is($t->parse('4: <#4>, 5: <#5>', 4=>'four', 5=>'five'),
    $expected3, "parse() - string and hash of tags supplied as arguments.");
 is($t->parse( '9: <#9>, B: <#B>', +{ 9 => 'A', B => 'C' } ), $expected4,
    "parse() - string and hashref of tags supplied as arguments.");
}

ok($t->template_file( 'test.html' ), "template_file() - Set template filename.");
is($t->template_file,'test.html', "template_file() - Get template filename.");

my $string2 = 'N: <#N>';
ok($t->entry_string( $string2 ), "entry_string() - Set string.");
is($t->entry_string,$string2,"entry_string() - Get string.");

ok($t->entry_file( 'test-entry.htmlf' ), "entry_file() - Set filename.");
is($t->entry_file,'test-entry.htmlf', "entry_file() - Get filename.");

ok($t->entry_callback( sub { return +{ N => $_[ 0 ] } } ), "entry_callback() - Set callback subroutine.");
like($t->entry_callback,'/^CODE\(0x[0-9a-f]+\)/',"entry_callback() - Returns a CODE ref.");

my $string3 = ', ';
ok($t->join_string($string3),"join_string() - Set the string.");
is($t->join_string,$string3,"join_string() - Get the string.");

my $string4 = 'test-join.htmlf';
ok($t->join_file( $string4 ), "join_file() - Set the join filename.");
is( $t->join_file, $string4, "join_file() - Get the join filename.");

undef $expected;
$expected = '1 2 3 4';
ok($t->join_tags( 1 => 2, 3 => 4 ), "join_tags() - Set using a hash.");
is(join( ' ', sort %{ $t->join_tags } ),$expected, "join_tags() - Get the tags set with a hash.");
ok($t->join_tags( {1 => 2, 3 => 4} ), "join_tags() - Set using a hashref.");
is(join( ' ', sort %{ $t->join_tags } ),$expected, "join_tags() - Get the tags set with a hashref.");

is($t->parse_file, "1: TAG ONE, 3: TAG THREE\n", "parse_file() - use template file set with template_file().");
is($t->parse_file('test.html'), "1: TAG ONE, 3: TAG THREE\n", "parse_file() - using template file supplied to function.");
is($t->parse_file( 'test.html', 1 => 'UNO', 3 => 'TRES' ),
   "1: UNO, 3: TRES\n", "parse_file() - template file & hash of tags supplied to function.");
is($t->parse_file( 'test.html', +{1 => 'I', 3 => 'III'} ),
   "1: I, 3: III\n", "parse_file() - template file & hashref of tags supplied to function.");

is($t->parse_list,'N: 1, N: 2, N: 3, N: 4, N: 5',"parse_list() - using previously supplied list etc." );
is($t->parse_list( +[ 6, 7, 8, 9, 'A' ] ),'N: 6, N: 7, N: 8, N: 9, N: A',
     "parse_list() - using listref supplied to function.");
is($t->parse_list( +[ 6, 7, 8, 9, 'A' ], 'M: <#N>' ),'M: 6, M: 7, M: 8, M: 9, M: A' ,
     "parse_list() - listref and entry string supplied to function.");
is($t->parse_list( +[ 6, 7, 8, 9, 'A' ], 'O: <#N>', '; ' ), 'O: 6; O: 7; O: 8; O: 9; O: A',
    "parse_list() - listref, entry string, join string supplied to function.");
is($t->parse_list( +[ 6, 7, 8, 9, 'A' ],
                   'P: <#P>',
                   '; ',
                   sub { return +{ P => $_[ 0 ] } }),
                   'P: 6; P: 7; P: 8; P: 9; P: A',
                   "parse_list() - listref, entry string, join string, entry callback supplied to function."
);

is($t->parse_list( +[ 6, 7, 8, 9, 'A' ],
   'P: <#P>', '-1: <#1>, 3: <#3>-',
   sub { return +{ P => $_[ 0 ] } },
   1 => 2, 3 => 4 ),
   'P: 6-1: 2, 3: 4-P: 7-1: 2, 3: 4-P: 8-1: 2, 3: 4-P: 9-1: 2, 3: 4-P: A',
   "parse_list() - listref, entry string, join string, entry callback, join tags supplied as hash to function."
);

is($t->parse_list(
      +[ 6, 7, 8, 9, 'A' ],
      'P: <#P>',
      '-1: <#1>, 3: <#3>-',
      sub { return +{ P => $_[ 0 ] } },
       +{ 1 => 2, 3 => 4 }
    ),
    'P: 6-1: 2, 3: 4-P: 7-1: 2, 3: 4-P: 8-1: 2, 3: 4-P: 9-1: 2, 3: 4-P: A',
    "parse_list() - listref, entry string, join string, entry callback, join tags supplied as hashref to function."
);


$expected = <<'eot';
N: 1
1: TAG ONE, 3: TAG THREE
N: 2
1: TAG ONE, 3: TAG THREE
N: 3
1: TAG ONE, 3: TAG THREE
N: 4
1: TAG ONE, 3: TAG THREE
N: 5
eot
is( $t->parse_list_files, $expected, "parse_list_files()");

$expected = <<'eot';
N: 6
1: TAG ONE, 3: TAG THREE
N: 7
1: TAG ONE, 3: TAG THREE
N: 8
1: TAG ONE, 3: TAG THREE
N: 9
1: TAG ONE, 3: TAG THREE
N: A
eot
is( $t->parse_list_files( +[ 6, 7, 8, 9, 'A' ] ),
    $expected,
    "parse_list_file() - using listref supplied to function.");

is( $t->parse_list_files( +[ 6, 7, 8, 9, 'A' ], 'test-entry.htmlf' ),
    $expected,
    "parse_list_file() - using listref and entry file supplied to function.");

is( $t->parse_list_files( +[ 6, 7, 8, 9, 'A' ], 'test-entry.htmlf', 'test-join.htmlf' ),
    $expected,
    "parse_list_file() - using listref, entry file, and join file supplied to function.");

is( $t->parse_list_files( +[ 6, 7, 8, 9, 'A' ], 'test-entry.htmlf', 'test-join.htmlf', sub { return +{ N => $_[ 0 ] } } ),
    $expected,
    "parse_list_file() - using listref, entry file, join file, and callback supplied to function.");
    
is( $t->parse_list_files(
       +[ 6, 7, 8, 9, 'A' ],
       'test-entry.htmlf',
       'test-join.htmlf',
       sub { return +{ N => $_[ 0 ] } },
       1 => 'TAG ONE', 3 => 'TAG THREE'       
      ),
    $expected,
    "parse_list_file() - using listref, entry file, join file, callback, and tags hash supplied to function.");
 
is( $t->parse_list_files(
       +[ 6, 7, 8, 9, 'A' ],
       'test-entry.htmlf',
       'test-join.htmlf',
       sub { return +{ N => $_[ 0 ] } },
       { 1 => 'TAG ONE', 3 => 'TAG THREE' }      
      ),
    $expected,
    "parse_list_file() - using listref, entry file, join file, callback, and tags hashref supplied to function.");

$expected = qq{W: <#W P="Space: Tab:\tCR:\nLT:&lt;GT:&gt;Equals:&#061;Amp:&amp;Quote:&quot;">};
$t->unknown_action( 'IGNORE' );
is($t->parse(  $expected ), $expected, "Parsing with unknown_action() to IGNORE.");

$t->add_tag( W => sub {
	my %params = %{ $_[ 0 ] };
	return $params{ P };
} );

my $string = qq{W: <#W P="Space: Tab:\tCR:\nLT:&lt;GT:&gt;Equals:&#061;Amp:&amp;Quote:&quot;">};
$expected = qq{W: Space: Tab:\tCR:\nLT:<GT:>Equals:=Amp:&Quote:"};
is($t->parse($string),
   $expected,
   "Parameters with whitespace and interesting characters are handled right.");


$t->add_tag( EMBEDTEST => sub {
	my %params = %{ $_[ 0 ] };
        my $result;
        foreach my $attr (sort keys %params) {
             $result .= qq{$attr="$params{$attr}"};
        }
	return $result;
} );
$t->add_tag( EMBED_1 => sub {
	my %params = %{ $_[ 0 ] };
	return $params{ATTR_1};
} );
$string = qq{EMBEDDED TAG: <#EMBEDTEST name="<#EMBED_1 ATTR_1="hello">">};
$expected = q{EMBEDDED TAG: NAME="hello"} ;
is($t->parse($string),$expected,"Tags embedded in tags are handled correctly.");

$string = qq{EMBEDDED TAG: <#EMBEDTEST name="<#EMBED_1 ATTR_1="hello=world">">};
$expected = q{EMBEDDED TAG: NAME="hello=world"};
is($t->parse($string),$expected,"Are attribute values containing '=' in embedded tags are handled correctly?");

$expected = 'Zero: 0';
$t->add_tag( ZERO => sub { 0; } );
is($t->parse('Zero: <#ZERO>'),$expected,"Is 0 (zero) handled properly as a replacement value?");


my $tag_start    = '&start;';
my $tag_content = '[^&]*';
my $tag_end      = '&end;';
my $regex = qr/$tag_start($tag_content)$tag_end/;
# print "Change the tag pattern to '$regex'\n";
$t->tag_start('&start;');
$t->tag_contents('[^&]*');
$t->tag_end('&end;');
is($t->tag_pattern, $regex, "tag_start(), tag_contents(), tag_end(), tag_pattern() all work?");


$expected = 'Hello 0';
$t->add_tag( ZERO => sub { 0; } );
is($t->parse( 'Hello &start;ZERO&end;' ),
   $expected,
   "Parse using the new tag_pattern $regex");


$tag_start = '/\*';
$tag_content = '[^*]*';
$tag_end     = '\*/';
$regex = qr/$tag_start($tag_content)$tag_end/;
$t->tag_start($tag_start);
$t->tag_contents($tag_content);
$t->tag_end($tag_end);
is($t->tag_pattern,$regex,"Changing tag_pattern again.");

$expected = qq{W: Space: Tab:\tCR:\nLT:<GT:>Equals:=Amp:&Quote:" */**};
$string = qq{W: /*W P="Space: Tab:\tCR:\nLT:&lt;GT:&gt;Equals:&#061;Amp:&amp;Quote:&quot;"*/ */**};
is($t->parse($string), $expected, "parse() using tag_pattern $regex");
