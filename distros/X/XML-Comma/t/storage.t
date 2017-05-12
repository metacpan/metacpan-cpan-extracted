use strict;
use File::Path;

use lib ".test/lib/";

use XML::Comma;
use XML::Comma::Util qw( dbg );

use File::Spec;
$|++;

use Test::More 'no_plan';

my $def = XML::Comma::Def->read ( name => '_test_storage' );

## test getting storage names from the def
my $names_string = join ( ',', sort $def->store_names() );
ok( $names_string eq 'eight,eleven,five,four,fourteen,nine,one,seven,six,ten,thirteen,three,twelve,two' );

#####
# test storage one -- two sequential_dirs and a sequential_file
#
my $storage_one = $def->get_store ( 'one' );
rmtree ( $storage_one->base_directory(), 0 );

my $doc = XML::Comma::Doc->new ( type => '_test_storage' );
ok( $doc );

# write a doc and check the storage key and locked status
$doc->element('el')->set(1);
ok( $doc->store( store => 'one', keep_open => 1 )->doc_key() eq '_test_storage|one|1101' );
ok( $doc->doc_is_locked() ); # because we keep_open'd
ok( ! $doc->get_read_only() ); # ditto

# do some blob setting and checking
$doc->element('bl')->set("basic set");
ok( $doc->element('bl')->get() eq 'basic set' );
my $tempfile = File::Spec->catfile( XML::Comma->tmp_directory(), 'sttest.tmp' );
open ( FILE, ">$tempfile" ) || die "couldn't open temp file: $!\n";
print FILE "temp file set";
close FILE;
$doc->element('bl')->set_from_file ( $tempfile );
unlink $tempfile;
ok( $doc->element('bl')->get() eq 'temp file set' );
ok( (-r $doc->element('bl')->get_location()) );
$doc->element('bl')->set();
ok( ! (-r $doc->element('bl')->get_location()) );

$doc->element('bl')->set ("another set for bl");
$doc->element('bl2')->set("first set for bl2");
ok( $doc->element('bl')->get() eq 'another set for bl' );
ok( $doc->element('bl2')->get() eq 'first set for bl2' );

# store to write the changed links to the blobs
$doc->store(keep_open=>1);
ok( $doc->element('bl')->get() eq 'another set for bl' );
ok( $doc->element('bl2')->get() eq 'first set for bl2' );
my $pattern = '1101-.{8}\.b$';
ok( $doc->element('bl')->get_location() =~ /$pattern/ );

# delete bl2 -- there should be no content and no location returned
my $blob_location = $doc->element('bl2')->get_location();
ok( -r $blob_location );
$doc->delete_element ( $doc->element('bl2') );
ok( ! $doc->element('bl2')->get_location() );
ok( ! $doc->element('bl2')->get() );
# refill b2 and re-delete, just to make things confusing
$doc->element('bl2')->set("bl2 again");
$doc->delete_element ( $doc->element('bl2') );
# store, and the original file should be gone
$doc->store(keep_open=>1);
ok( "didn't die trying to store" );
ok( ! -r $blob_location );

# put things back the way they were
$doc->element('bl2')->set("first set for bl2");
$doc->store(keep_open=>1);
ok( $doc->element('bl2')->get() eq 'first set for bl2' );
# delete again, then forget about the changes, reread the doc and
# check the value
my $doc_key = $doc->doc_key();
$doc->delete_element ( $doc->element('bl2') );
undef $doc; $doc = XML::Comma::Doc->retrieve ( $doc_key );
ok( $doc->element('bl2')->get() eq 'first set for bl2' );
# same thing, but with an empty set()
$doc->element('bl2')->set();
undef $doc; $doc = XML::Comma::Doc->retrieve ( $doc_key );
ok( $doc->element('bl2')->get() eq 'first set for bl2' );
# same thing, but with some other content
$doc->element('bl2')->set ( "foo" );
undef $doc; $doc = XML::Comma::Doc->retrieve ( $doc_key );
ok( $doc->element('bl2')->get() eq 'first set for bl2' );
# this time, set to empty, then store, then set, then throwaway and check
$doc->element('bl2')->set();
$doc->store(keep_open=>1);
ok( ! $doc->element('bl2')->get() );
$doc->element('bl2')->set( "foo" );
undef $doc; $doc = XML::Comma::Doc->retrieve ( $doc_key );
ok( ! $doc->element('bl2')->get() );

# put some content back into bl2
$doc->element('bl2')->set( "bl2 forever" );
$doc->store(keep_open=>1);

$blob_location = $doc->element('bl')->get_location();

# copy, and make sure the copy looks okay
$doc->element('el')->set(2);
ok($doc->copy(keep_open=>1)->doc_key() eq '_test_storage|one|1102' );
ok($doc->element('bl')->get_location() ne $blob_location );
ok($doc->element('bl')->get() eq 'another set for bl' );
ok($doc->element('bl2')->get() eq 'bl2 forever' );


# now unset the blobs, do one more copy and check to make sure there
# are no blobs
$doc->element('bl')->set();
$doc->element('bl2')->set();
$doc->element('el')->set(3);
ok( $doc->copy()->doc_key() eq '_test_storage|one|1103' );
ok( ! defined  $doc->element('bl')->get() );
ok( ! defined  $doc->element('bl2')->get() );
ok( $doc->element('bl2')->get_location() eq '' );

# read the three docs in and check that 'el' is correct
ok( XML::Comma::Doc->retrieve('_test_storage|one|1101')->el() eq '1' );
ok( XML::Comma::Doc->retrieve('_test_storage|one|1102')->el() eq '2' );
ok( XML::Comma::Doc->retrieve('_test_storage|one|1103')->el() eq '3' );


# now let's make a couple of iterators, and check that they work
my $it = $storage_one->iterator();
ok( $it->prev_id() eq '1103' );
ok( $it->prev_id() eq '1102' );
ok( $it->prev_id() eq '1101' );
ok( ! $it->prev_id() );

$it = $storage_one->iterator( pos => '-' );
ok( $it->next_id() eq '1101' );
ok( $it->next_id() eq '1102' );
ok( $it->next_id() eq '1103' );
ok( ! $it->next_id() );

$it = $storage_one->iterator( size=>2 );
ok( $it->prev_id() eq '1103' );
ok( $it->prev_id() eq '1102' );
ok( ! $it->prev_id() );

$it = $storage_one->iterator( size=>2, pos=>'-' );
ok( $it->next_id() eq '1101' );
ok( $it->next_id() eq '1102' );
ok( ! $it->next_id() );

# now we should check one of these, to make sure it's in the right place
$doc = XML::Comma::Doc->retrieve ( '_test_storage|one|1103' );

my $filename = File::Spec->catfile ( $storage_one->base_directory(),
                                     '1', '1', '03.one' );
ok( $doc->doc_location() eq $filename );
ok( -r $filename );

# erase
$doc->erase();
ok( ! (-r $filename) );

# move -- since 01 also has blobs, this checks that blobs are
# successfully moved on a move (and, by implication, erased on erase).
$doc = XML::Comma::Doc->retrieve ( '_test_storage|one|1101' );
my $blob_location1 = $doc->element('bl')->get_location();
my $blob_location2 = $doc->element('bl2')->get_location();
$doc->move();
ok( $doc->doc_key() eq '_test_storage|one|1104' );
ok( ! ( -r File::Spec->catfile($storage_one->base_directory, '1','1','01.one') ) );
ok( ! ( -r $blob_location1 ) );
ok( ! ( -r $blob_location2 ) );
$blob_location1 = $doc->element('bl')->get_location();
$blob_location2 = $doc->element('bl2')->get_location();
ok( -r $blob_location1 );
ok( -r $blob_location2 );

# change and store
$doc = XML::Comma::Doc->retrieve ( $doc->doc_key() );
$doc->el(4);
$doc->store();
ok( XML::Comma::Doc->retrieve($doc->doc_key())->el() eq '4' );
ok( $doc->doc_key() eq '_test_storage|one|1104' );

# store again, this time using the same store name explicitly, to make
# sure that the if'age in Doc->store does the right thing with an
# explicit-but-matching store name.
$doc = XML::Comma::Doc->retrieve ( $doc->doc_key() );
$doc->store ( store => 'one' );
ok( $doc->doc_key() eq '_test_storage|one|1104' );

# loop storing 36/40 docs -- we've already stored 4 in the above tests
foreach ( 1..36 ) {
  $doc->copy();
}
ok("didn't die on all those doc copies");
# store the next and get a storage full error
eval { $doc->copy(); };
ok( $@ );

#
# test looping forwards through id-space
my $n = '0000'; my $counter = 0;
while ( $n = $storage_one->next_id($n) ) {
  $counter++;
}
ok( $counter == 38 );

# test first_id and last_id
ok( $storage_one->first_id() eq '1102' );
ok( $storage_one->last_id() eq '2210' );

# and the + and - id syntaxes for first and last stored
ok( XML::Comma::Doc->retrieve ( '_test_storage|one|-' )->el() eq '2' );
ok( XML::Comma::Doc->retrieve ( '_test_storage|one|+' )->el() eq '4' );

# test the exported method from Storage_file
ok( $storage_one->extension() eq '.one' );

# test touch and last_modified
my $lm = $doc->doc_last_modified();
sleep ( 1 );
my $nm = $storage_one->touch ( $doc->doc_location() );
ok( $nm gt $lm and $nm == $doc->doc_last_modified() );

# test locking
$doc = XML::Comma::Doc->retrieve ( "_test_storage|one|-" );
ok( $doc );
ok( $doc->doc_is_locked() );
my $ro = XML::Comma::Doc->read ( "_test_storage|one|-" );
ok( ! $ro->doc_is_locked() );
ok( ! defined XML::Comma::Doc->retrieve_no_wait ( "_test_storage|one|-" ) );
eval {
  XML::Comma::Doc->retrieve ( "_test_storage|one|-", timeout=>0 );
};
ok( $@ );
eval {
  XML::Comma::Doc->retrieve ( "_test_storage|one|-", timeout=>1 );
};
ok( $@ );
eval {
  $doc->get_lock ( timeout=>0 );
};
ok( $@ );
# should not be able to store ro
eval { $ro->store() };
ok( $@ );
# try to store with keep open
$doc->store ( keep_open=>1 );
ok( $doc->doc_is_locked() );
# and now store again and we should be unlocked
$doc->store ();
ok( ! $doc->doc_is_locked() );
$doc->get_lock();
ok( $doc->doc_is_locked() );
ok( ! defined $ro->get_lock_no_wait() );
ok( ! $ro->doc_is_locked() );

#
#
####

####
# storage six -- Derived_file (with a Sequential_dir thrown in for excitement)

rmtree  $def->get_store('six')->base_directory();

$doc = XML::Comma::Doc->new ( type => '_test_storage' );
$doc->el('first');
$doc->store ( store=>'six' );
my $doc2 = XML::Comma::Doc->new ( type => '_test_storage' );
$doc2->el('second');
$doc2->store ( store=>'six' );
$doc = XML::Comma::Doc->read ( '_test_storage|six|1first' );
ok( $doc->el() eq 'first' );
$doc = XML::Comma::Doc->read ( '_test_storage|six|1second' );
ok( $doc->el() eq 'second' );
# now modify the derive_from
$doc->get_lock();
$doc->el('modified');
$doc->store();
$doc = XML::Comma::Doc->read ( '_test_storage|six|1second' );
ok( $doc->el() eq 'modified' );
#
ok( $doc->doc_location eq
  File::Spec->catfile ( $doc->doc_store()->base_directory(), '1',
                        'second' . $doc->doc_store()->extension() )
);

my $storage_six = $def->get_store ( 'six' );
my $six_first_id = $storage_six->first_id();
ok( $six_first_id eq '1first' );

#
#
####


####
# storage eleven -- Derived_GMT_3layer_dir (in a sandwich)

$doc = XML::Comma::Doc->new ( type => '_test_storage' );
$doc->el('20020416'); $doc->el2('foo');
$doc->store ( store=>'eleven' );
$doc2 = XML::Comma::Doc->new ( type => '_test_storage' );
$doc2->el('20020416'); $doc2->el2('bar');
$doc2->store ( store=>'eleven' );
$doc = XML::Comma::Doc->read ( '_test_storage|eleven|120020416foo' );
ok( $doc->el2() eq 'foo' );
$doc = XML::Comma::Doc->read ( '_test_storage|eleven|120020416bar' );
ok( $doc->el2() eq 'bar' );
# now modify the derive_from
$doc->get_lock();
$doc->el('19990101');
$doc->store();
$doc = XML::Comma::Doc->read ( '_test_storage|eleven|120020416bar' );
ok( $doc->el() eq '19990101' );
#
ok( $doc->doc_location eq
  File::Spec->catfile ( $doc->doc_store()->base_directory(), '1',
                        '2002', '04', '16',
                        'bar' . $doc->doc_store()->extension() )
);

my $storage_eleven = $def->get_store ( 'eleven' );
my $eleven_first_id = $storage_eleven->first_id();
ok( $eleven_first_id eq '120020416bar' );

#
#
####

####
# storage seven -- Derived_dir (with other stuff thrown in for excitement)
rmtree  $def->get_store('seven')->base_directory();

$doc = XML::Comma::Doc->new ( type => '_test_storage' );
$doc->el ( '1' ); # too short
$doc->store ( store=>'seven' );
ok( $doc->doc_key() eq '_test_storage|seven|10011' );
$doc2 = XML::Comma::Doc->read ( $doc->doc_key() );
ok( $doc2->el() eq '1' );
#
$doc = XML::Comma::Doc->new ( type => '_test_storage' );
$doc->el ( '11111' ); # too long
$doc->store ( store=>'seven' );
ok( $doc->doc_key() eq '_test_storage|seven|111111111' );
$doc2 = XML::Comma::Doc->read ( $doc->doc_key() );
ok( $doc2->el() eq '11111' );
#
#
####

####
# storage two - gmt dir and a sequential file

my $storage_two = $def->get_store ( 'two' );
my ( $year, $month, $day ) = XML::Comma::Storage::Util->gmt_yyyy_mm_dd();
my $two_base_loc = File::Spec->catdir 
  ( $storage_two->base_directory(), $year, $month, $day );
my $two_base_id = join ( '', $year, $month, $day );

rmtree ( $storage_two->base_directory(), 0 );

# simple set and store
$doc = XML::Comma::Doc->new ( type => '_test_storage' );
$doc->element('el')->set ( 'first gmt 3 layer doc' );
ok( $doc->store(store=>'two',keep_open=>1)->doc_key() eq "_test_storage|two|$two_base_id".'01' );

# change the element, and retrieve
$doc->element('el')->set ( 'changed' );
$doc->doc_unlock();
$doc = XML::Comma::Doc->retrieve ( "_test_storage|two|$two_base_id".'01' );
ok( $doc->el() eq 'first gmt 3 layer doc' );

# only nine more should fit
for ( 1..9 ) {
  $doc->copy();
}
ok("nine more stores");
eval { $doc->copy(); };
ok( $@ );

# check blob and blob's read hook
$doc = XML::Comma::Doc->retrieve ( "_test_storage|two|$two_base_id".'01' );
ok( $doc->element('bl')->def_pnotes()->{read_setted} eq 'ok' );
$doc->element('bl')->set ( 'a blob thing' );
ok( $doc->element('bl')->get() eq 'a blob thing' );

#
#
####


####
# output chains

rmtree  $def->get_store('three')->base_directory();
rmtree  $def->get_store('four')->base_directory();
rmtree  $def->get_store('five')->base_directory();

# gzip
$doc = XML::Comma::Doc->new ( type => '_test_storage' );
$doc->element('el')->set(45);
ok( $doc->store( store => 'three' )->doc_key() eq '_test_storage|three|01' );
$doc2 = XML::Comma::Doc->read ( '_test_storage|three|01' );
ok( $doc2->element('el')->get() == 45 );

# twofish
$doc = XML::Comma::Doc->new ( type => '_test_storage' );
$doc->element('el')->set(79);
ok( $doc->store( store => 'four' )->doc_key() eq '_test_storage|four|01' );
$doc2 = XML::Comma::Doc->read ( '_test_storage|four|01' );
ok( $doc2->element('el')->get() == 79 );

# gzip then twofish
$doc = XML::Comma::Doc->new ( type => '_test_storage' );
$doc->element('el')->set(223);
ok( $doc->store( store => 'five' )->doc_key() eq '_test_storage|five|01' );
$doc2 = XML::Comma::Doc->read ( '_test_storage|five|01' );
ok( $doc2->element('el')->get() == 223 );

# exit ( 0 );

####
# hooks
####

rmtree  $def->get_store('eight')->base_directory();

$doc = XML::Comma::Doc->new ( type => '_test_storage' );
$doc->store ( store => 'eight' );
ok( $doc->el() eq 'one-hook;two-hooks;three-hooks' );
my $key = $doc->doc_key();
ok( XML::Comma::Doc->read( $key )->el() eq 'one-hook;two-hooks;three-hooks' );
$doc = XML::Comma::Doc->new ( type => '_test_storage' );
$doc->store ( store => 'eight', no_hooks => 1 );
ok( $doc->el() eq '' );
$doc = 1;


####
# Derived-file directory "balancing"
####
my $nine_base = $def->get_store('nine')->base_directory();
my $ten_base = $def->get_store('ten')->base_directory();
#
$doc = XML::Comma::Doc->new ( type => '_test_storage' );
$doc->el ( 'abcd' );
$doc->store ( store => 'nine' );
ok( $doc->doc_key() eq '_test_storage|nine|abcd' );
ok( $doc->doc_location() eq File::Spec->catfile ( $nine_base, 'cd', 'abcd.comma' ) );
$doc = XML::Comma::Doc->retrieve ( '_test_storage|nine|abcd' );
$doc->store ( store => 'ten' );
ok( $doc->doc_key() eq '_test_storage|ten|0001abcd' );
ok( $doc->doc_location() eq File::Spec->catfile ( $ten_base, '0001', 'ab', 'abcd.comma' ) );
$doc = XML::Comma::Doc->retrieve ( '_test_storage|ten|0001abcd' );
ok( $doc->el() eq 'abcd' );

####
# different digit sets in Sequential_dir and Sequential_file
####
rmtree  $def->get_store('twelve')->base_directory();
$doc = XML::Comma::Doc->new ( type => '_test_storage' );
$doc->el ( '123' );
$doc->store ( store => 'twelve' );
ok( $doc->doc_id() eq 'yab' );
$doc->copy();
ok( $doc->doc_id() eq 'yac' );
$doc->copy();
ok( $doc->doc_id() eq 'yba' );
$doc->copy();
ok( $doc->doc_id() eq 'ybb' );
$doc->copy();
ok( $doc->doc_id() eq 'zab' );
$doc->copy();
ok( $doc->doc_id() eq 'zac' );

####
# Timestamped randoms
####
rmtree  $def->get_store('thirteen')->base_directory();
$doc = XML::Comma::Doc->new ( type => '_test_storage' );
$doc->el ( '0xfoo' );
$doc->store ( store => 'thirteen' );
my $id = $doc->doc_id;
ok( length($id) == 16 );
$doc2 = XML::Comma::Doc->read ( $doc->doc_key );
ok( $doc2->doc_id eq $id );
rmtree  $def->get_store('fourteen')->base_directory();
$doc = XML::Comma::Doc->new ( type => '_test_storage' );
$doc->el ( '0xbar' );
$doc->store ( store => 'fourteen' );
$id = $doc->doc_id;
ok( length($id) == 17 );
$doc2 = XML::Comma::Doc->read ( $doc->doc_key );
ok( $doc2->doc_id eq $id );

###
# test for the iterator with size offset across a multi-directory store problem
###
$it = $storage_one->iterator( size => 2 );
ok( $it->prev_id eq '2210' );
ok( $it->prev_id eq '2209' );
$it = $storage_one->iterator( size => 2, pos => '-' );
ok($it->next_id eq '1102' );
ok($it->next_id eq '1104' );

###
# check overloading for while(++$it)
###
$it = $storage_one->iterator();
$doc = $it->read_doc;
ok( $doc->doc_id eq '2210' );
$it++; $doc = $it->read_doc; #first ++ is a null op for while(++$it) setups
ok( $doc->doc_id eq '2210' );
$it++; $doc = $it->read_doc;
ok( $doc->doc_id eq '2209' );
$it++; $doc = $it->read_doc;
ok( $doc->doc_id eq '2208' );
$it--; $doc = $it->read_doc;
ok( $doc->doc_id eq '2209' );
ok( $it ); #we've still got more in here...

$it = $storage_one->iterator( pos => '-');
$doc = $it->read_doc;
ok( $doc->doc_id eq '1102' );
$it++; $doc = $it->read_doc; #first ++ is a null op for while(++$it) setups
ok( $doc->doc_id eq '1102' );
$it++; $doc = $it->read_doc;
ok( $doc->doc_id eq '1104' );
$it++; $doc = $it->read_doc;
ok( $doc->doc_id eq '1105' );
$it--; $doc = $it->read_doc;
ok( $doc->doc_id eq '1104' );
ok( $it ); #we've still got more in here...

$it = $storage_one->iterator( size => 2 );
$doc = $it->read_doc;
ok( $doc->doc_id eq '2210' );
$it++; $doc = $it->read_doc; #first ++ is a null op for while(++$it) setups
ok( $doc->doc_id eq '2210' );
$it++; $doc = $it->read_doc;
ok( $doc->doc_id eq '2209' );
ok( $it ); #one more left
$it++;
ok( !$it ); #nothing left

$it = $storage_one->iterator( size => 2, pos => '-' );
$doc = $it->read_doc;
ok( $doc->doc_id eq '1102' );
$it++; $doc = $it->read_doc; #first ++ is a null op for while(++$it) setups
ok( $doc->doc_id eq '1102' );
$it++; $doc = $it->read_doc;
ok( $doc->doc_id eq '1104' );
ok( $it ); #one more left
$it++;
ok( !$it ); #nothing left

####
# test next_in_list function
my @list = ( 'a', 'b', 'c', 'd',   'f', 'g', 'h', 'i' );
# simple
ok( 'b' eq XML::Comma::Storage::FileUtil->next_in_list ( \@list, 'a' ) );
ok( 'g' eq XML::Comma::Storage::FileUtil->next_in_list ( \@list, 'f' ) );
ok( 'h' eq XML::Comma::Storage::FileUtil->next_in_list ( \@list, 'i', -1 ) );
ok( 'c' eq XML::Comma::Storage::FileUtil->next_in_list ( \@list, 'd', -1 ) );
# past ends
ok( ! defined XML::Comma::Storage::FileUtil->next_in_list ( \@list, 'i' ) );
ok( ! defined XML::Comma::Storage::FileUtil->next_in_list ( \@list, 'a', -1 ) );
# into ends
ok( 'a' eq XML::Comma::Storage::FileUtil->next_in_list ( \@list, '0' ) );
ok( 'i' eq XML::Comma::Storage::FileUtil->next_in_list ( \@list, 'z', -1 ) );
# over gap
ok( 'f' eq XML::Comma::Storage::FileUtil->next_in_list ( \@list, 'd' ) );
ok( 'd' eq XML::Comma::Storage::FileUtil->next_in_list ( \@list, 'f', -1 ) );

###test iterator shortcut syntax
$it = $storage_one->iterator( size => 2, pos => '-' );

#making sure doc_id() and read_doc don't advance any pointers
$doc = $it->read_doc;
my $did = $it->doc_id;
ok($doc->doc_id eq $did);
$it->doc_id;
ok($it->doc_id eq $did);

#first call to ++$it DOES NOT advance the pointer
# for while(++$it) compatibility
++$it;
ok($doc->doc_id eq $did);
ok($it->doc_id eq $did);

$doc = $it->read_doc;
#test shortcut syntax
ok($doc->el2 eq $it->el2);
ok($doc->el eq $it->el);
ok($doc->flagged eq $it->flagged);

#now, make sure we *DO* advance
++$it;
ok($it->doc_id ne $did);

$doc = $it->read_doc;
#test shortcut syntax (again)
ok($doc->el2 eq $it->el2);
ok($doc->el eq $it->el);
ok($doc->flagged eq $it->flagged);

###test iterator shortcut syntax
$it = $storage_one->iterator( size => 2, pos => '-' );

#call $it->some_field right off the bat and make sure it does the
#right thing. this is an expected difference from the behavior with
#doc_id
my $el = $it->el;
++$it;
ok($el ne $it->el);
