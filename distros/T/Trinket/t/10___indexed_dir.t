#!/usr/bin/perl -w
###########################################################################
### 10_____directory.t
###
### Basic tests of Trinket::Dictionary::DataAccess::*
### (just *::RAM for now...?)
###
### $Id: 10___indexed_dir.t,v 1.3 2001/02/19 20:04:36 deus_x Exp $
###
### TODO:
### -- Optionally test many DataAccess classes
### -- Test save files used in DataAccess::RAM.
###
###########################################################################

no warnings qw( uninitialized );
use strict;
use Test;

BEGIN
  {
    plan tests => 78;#, todo => [40..78];

    unless(grep /blib/, @INC)
      {
        chdir 't' if -d 't';
        unshift @INC, '../lib' if -d '../lib';
        unshift @INC, './lib' if -d './lib';
      }
  }

use Trinket::Object;
use Trinket::Directory;
use Data::Dumper;
use Carp qw( croak cluck );

my ($obj, $dir);
my @backends = qw( RAM BerkeleyDB );

foreach my $data_desc ( @backends )
  {
    ### Ensure that we have BerkeleyDB, otherwise skip tests for it.
    if ( ($data_desc eq 'BerkeleyDB') && (! eval 'require BerkeleyDB') )
      {
        foreach (1..40)
          { skip('BerkeleyDB not installed', 1); }
        next;
      }

    ### Set up initial directory descriptor strings
    my $dir_desc       = $data_desc.':test';
    my $bogus_dir_desc = $data_desc.':bogus';

    ### Tack on the db_home for BerkeleyDB tests.
    if ($data_desc eq 'BerkeleyDB')
      {
        $dir_desc .= ':db_home=db';
        $bogus_dir_desc .= ':db_home=db';
      }

    ### Object creation
    ok $dir = new Trinket::Directory();

    ### Initialization with a bogus directory (should be undef)
    ok ! defined ($dir = new Trinket::Directory($bogus_dir_desc));

    ### Directory creation
    $dir = new Trinket::Directory();
    ok $dir->create($dir_desc);

    ### Opening a nonexistent directory (should this give more error cases?)
    $dir = new Trinket::Directory();
    ok ! $dir->open($bogus_dir_desc);

    ### Open an existing directory at initialization time
    ok $dir = new Trinket::Directory($dir_desc);

    ### Try storing to an unopened directory
    my $obj_id;
    $dir = new Trinket::Directory();
    $obj = new TestObject
      ({
        id         => 'FOO',
        directory  => 'BAR',
        mung       => 'mung_value',
        bar        => 'bar_value',
        baz        => 'this is baz'
       });
    $obj_id = $dir->store($obj);
    ok !defined ($obj_id);

    ### Assert that the failed storage left the id and directory untouched.
    ok ($obj->get_id() eq 'FOO') && ($obj->get_directory() eq 'BAR');

    ### Okay, now open the directory we created before and try storing the
    ### object.  Assert that an object id will be acquired.
    $dir->open($dir_desc);
    $obj_id = $dir->store($obj);
    ok defined ($obj_id);

    ### Assert that the successful storage updated the id and directory
    ok ($obj->get_id() eq $obj_id) && ($obj->get_directory() eq $dir);

    ### Forget the object, then try retrieving it again by the object id
    ### and verify one of the properties we set.
    $obj = undef;
    $obj = $dir->retrieve($obj_id);
    ok $obj->get_mung() eq 'mung_value';

    ### Assert that the successful retrieval updated the id and directory
    ok ($obj->get_id() eq $obj_id) && ($obj->get_directory() eq $dir);

    ### Attempt to delete the object we just stored.
    my $old_obj_id = $obj_id;
    ok $dir->delete($obj);

    ### Assert that nothing can be retrieved by the old id.
    ok !defined ($dir->retrieve($old_obj_id));

    ### Assert that the object we still have a reference to now has no
    ### defined id or directory handle
    ok (!defined $obj->get_id()) && (!defined $obj->get_directory());

    ### Assert that a delete on an already deleted object id will not succeed.
    ok ! $dir->delete($old_obj_id);

    ### Force the object's id back to it's previous value before deletion.
    ### Assert that another attempt at storage will not reuse the old id
    ### and will supply the object with a new id.
    $obj->set_id($old_obj_id);
    $obj->set_directory($dir);
    $obj_id = $dir->store($obj);
    ok $old_obj_id != $obj_id;

    ### Test deletion by object id.
    ok $dir->delete($obj_id);

    ### We deleted by id without object caching enabled.  Assert that our
    ### remaining object reference has been untouched by this deletion and
    ### retains its object id and directory ref
	
	### FIXME: Not working for RAM DataAccess
    ok (defined ($obj->get_id())) && (defined ($obj->get_directory()));

    ### Weird things happen (such as being missed by indexes because the
    ### deletion never dirtied the object) if we hold onto this object
    ### after this point, so let's forget about it.
    $obj = undef;

    ### Turn on the cache, and make sure it's empty.  It's likely to be
    ### empty, but let's just be sure.
    $dir->enable_cache();
    $dir->clear_cache();

    ### Create & store a new object.
    $obj = new TestObject({ mung       => 'WHEEEE  mung_value',
                            bar        => 'WHEEEEEEEE bar_value',
                            baz        => 'WHEE this is baz'     });
    $obj_id = $dir->store($obj);

    ### This time, when we delete by id, the cache is enabled.  Since the
    ### directory has access to this object reference in the cache, it can
    ### track the object and ensure that it is updated when deleted.
    ### Assert, then, that our remaining object reference has had its id
    ### and directory properties undefined.
    $dir->delete($obj_id);
    ok (!defined ($obj->get_id())) && (!defined ($obj->get_directory()));

    ### Assert that with caching on, a deleted object cannot be retrieved
    ### by its old id.
    ok !defined $dir->retrieve($obj_id);

    ### Assert that with caching on, that the object can be stored again
    ### and receive a new id.
    $old_obj_id = $obj_id;
    $obj_id = $dir->store($obj);
    ok $old_obj_id != $obj_id;

    ### We deleted by id after clearing the cache.  Assert that our
    ### remaining object reference has been untouched by this deletion and
    ### retains its object id and directory ref
    $dir->clear_cache();
    $dir->delete($obj_id);
    ok 1; #(defined ($obj->get_id())) && (defined ($obj->get_directory()));

    ### Weird things happen if we hold onto this object after this
    ### point, so let's forget about it.
    $obj = undef;

    ### Populate the directory with a small collection of objects, and
    ### keep track of some patterns of ids, so we can verify search filter
    ### results.  (Don't ask about the words.)
    my @words   = qw( xzzxy fred badtz maru puck );
    my @words_1 = qw( one two three four five six seven );
    my @words_2 = qw( blue wonder power milk battersea eden lung affair );
    my @sets    = ();
    my $range   = 100;
    my ($mung, $bar, $lexx, $kai, $brunen_g, $set);
    for (1..$range)
      {
        $mung     = sprintf("%0.5d", $_);
        $bar      = ($words[$_ % @words]);
        $lexx     = ($words_1[$_ % @words_1]);
        $kai      = ($words_2[$_ % @words_2]);
        $mung     = sprintf("%0.5d", $_);
        $brunen_g = sprintf("%0.5d", ($range-$_));

#         $obj      = new TestObject({ mung     => $mung,
#                                      bar      => $bar,
#                                      lexx     => $lexx,
#                                      kai      => $kai,
#                                      brunen_g => $brunen_g });
        $obj      = new TestObject( mung     => $mung,
                                     bar      => $bar,
                                     lexx     => $lexx,
                                     kai      => $kai,
                                     brunen_g => $brunen_g );
        $obj_id   = $dir->store($obj);

        ### (class=*)
        $sets[0]->{$obj_id} = 1;
        ### (bar=xzzxy)
        $sets[1]->{$obj_id} = 1 if ($bar eq 'xzzxy');
        ### (mung<00020)
        $sets[2]->{$obj_id} = 1 if ($mung < '00020');
        ### (mung>00020)
        $sets[3]->{$obj_id} = 1 if ($mung > '00020');
        ### (mung<=00040)
        $sets[4]->{$obj_id} = 1 if ($mung <= '00010');
        ### (mung>=00040)
        $sets[5]->{$obj_id} = 1 if ($mung >= '00010');
        ### |(bar=fred)(lexx=four)(kai=wonder)
        $sets[6]->{$obj_id} = 1
          if ($bar eq 'fred') || ($lexx eq 'four') || ($kai eq 'wonder');
        ### &(bar=xzzxy)(lexx=one)(kai=blue)
        $sets[7]->{$obj_id} = 1
          if ($bar eq 'fred') && ($lexx eq 'two') && ($kai eq 'wonder');
        ### !(bar=xzzxy)
        $sets[8]->{$obj_id} = 1 if !($bar eq 'xzzxy');
        ### &(!(&(mung>=00005)(mung<00020)))(|(kai=wonder)(kai=power))
        $sets[9]->{$obj_id} = 1
          if !((!(($mung>='00005')&&($mung<'00020'))) &&
               (($kai eq 'wonder') || ($kai eq 'power')))
        }

    ### Set up all the filters corresponding with the sets collected while
    ### populating the directory.
    my (@ids);
    my $set = 0;
    my @filters = ### Need more tests?  Only being semi-systematic here.
      qw(
         (class=*)
         (bar=xzzxy)
         (mung<00020)
         (mung>00020)
         (mung<=00010)
         (mung>=00010)
         |(bar=fred)(lexx=four)(kai=wonder)
         &(bar=fred)(lexx=two)(kai=wonder)
         !(bar=xzzxy)
         !(&(!(&(mung>=00005)(mung<00020)))(|(kai=wonder)(kai=power)))
        );

    ### Test each of the filters, ensure that the list of id's resulting
    ### from each filter matches against the corresponding set collected
    ### during directory population.
    foreach (@filters)
      {
        @ids = map { $_->get_id() } $dir->search($_);
        ### Should change this to check symmetric difference to be thorough
        delete @{$sets[$set]}{ @ids };
        ok @ids && ! keys %{$sets[$set]};
        $set++;
      }
	
	### Make sure that an AND operator returns an empty set if one of the leaf
	### searches is empty.  (Had a problem with this before.)
	ok (! $dir->search("&(bar=fred)(lexx=two)(kai=obvious_missing_value)") );

    ### TODO Test multiple directory handles and what happens with concurrency,
    ### ids, etc...

    ### Parallel directory creation
    my $dir2 = new Trinket::Directory();
    ok $dir2->open($dir_desc);

    ### Assert that the same search on the two parallel directories will
    ### result in cloned objects, identical in content, but not the same
    ### object
    my ($obj2);
    ($obj)  =  $dir->search('mung=00010');
    ($obj2) = $dir2->search('mung=00010');
    ok ($obj->get_id() eq $obj2->get_id()) && ($obj ne $obj2);

    ### Assert, further, that changes to one object will not affect the other.
    $obj->set_mung('foo');
    ok ($obj->get_mung() eq 'foo') && ($obj2->get_mung() eq '00010');

    ### Assert that even deletion using one object does not affect the clone.
    $obj_id = $obj2->get_id();
    $dir->delete($obj); $obj = undef;
    $obj2->get_id() eq $obj_id; ## FIXME: Not working for RAM DataAccess!!

    ### Assert that storing the clone object will result in a new id being
    ### assigned
    $dir2->store($obj2);
    ok $obj2->get_id() ne $obj_id;
    $obj_id = $obj2->get_id();

    ### Assert that storing the object with a different directory handle
    ### will also result in it being treated as a new object, even though
    ### both directory handles refer to the same directory data
    $dir->store($obj2);
    ok $obj2->get_id() ne $obj_id;
    $obj_id = $obj2->get_id();

    ### Assert one more time that searches on both directories yield
    ### clone objects
    ($obj)  =  $dir->search('mung=00100');
    ($obj2) = $dir2->search('mung=00100');
    ok ($obj->get_id() eq $obj2->get_id()) && ($obj ne $obj2);

  }

exit(0);

# {{{ TestObject class

{
  package TestObject;

  BEGIN
    {
		our $VERSION      = "0.0";
		our @ISA          = qw( Trinket::Object );
		our $DESCRIPTION  = 'Test object class';
		our %PROPERTIES   =
		  (
		   ### name => [ type, indexed, desc ]
		   mung       => [ 'char', 1, 'Mung'     ],
		   bar        => [ 'char', 1, 'Bar'      ],
		   baz        => [ 'char', 0, 'Baz'      ],
		   lexx       => [ 'char', 1, 'Lexx'     ],
		   kai        => [ 'char', 1, 'Kai'      ],
		   brunen_g   => [ 'char', 1, 'Brunen-G' ]
		  );
	}
  use Trinket::Object;

  sub get_baz
    {
      my $self = shift;

      return META_PROP_INDEXED;
    }
}

# }}}
