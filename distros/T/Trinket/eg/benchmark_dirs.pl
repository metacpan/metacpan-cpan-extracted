#!/usr/bin/perl -w
###########################################################################
### benchmark_dirs.pl
###
### Burn through some benchmarking of the functions of the directories
###
### $Id$
###
### TODO:
###
###########################################################################

use Trinket::Object;
use Trinket::Directory;
use Data::Dumper;
use Benchmark;

my @backends = qw( RAM BerkeleyDB );

my $create_num = 10000;

foreach my $data_desc ( @backends )
  {
    print "\nBenchmarking $data_desc...\n";
    ### Ensure that we have BerkeleyDB, otherwise skip tests for it.
    if ( ($data_desc eq 'BerkeleyDB') && (! eval 'require BerkeleyDB') )
      {
        print "...$data_desc not available, skipping.\n";
        next;
      }

    ### Set up initial directory descriptor strings
    my $dir_desc       = $data_desc.':test';
    my $bogus_dir_desc = $data_desc.':bogus';

    ### Tack on the db_home for BerkeleyDB tests.
    if ($data_desc eq 'BerkeleyDB')
      {
        $dir_desc .= ':db_home=db';
      }

    ### Directory creation
    $dir = new Trinket::Directory();
    $dir->create($dir_desc);

    my @obj_ids = ();
    {
      print "* Creating and storing $create_num objects:\n";
      my $t0 = new Benchmark;

      my ($mung, $bar, $lexx, $kai, $brunen_g, $set, $obj_id);
      for(1..$create_num)
        {
          $mung     = sprintf("%0.5d", $_);
          $brunen_g = sprintf("%0.5d", ($_));
          $obj      = new TestObject({ mung     => $mung,
                                       brunen_g => $brunen_g });
          $obj_id   = $dir->store($obj);

          push @obj_ids, $obj_id;
        }

      my $t1 = new Benchmark;
      my $td = Benchmark::timediff($t1,$t0);
      my $ts = Benchmark::timestr($td);
      print "\t$ts\n";
    }

    {
      print "* Retrieving $create_num objects:\n";
      my $t0 = new Benchmark;

      my ($mung, $bar, $lexx, $kai, $brunen_g, $set, $obj_id);
      foreach (@obj_ids)
        {
          $obj_id   = $dir->retrieve($_);
        }

      my $t1 = new Benchmark;
      my $td = Benchmark::timediff($t1,$t0);
      my $ts = Benchmark::timestr($td);
      print "\t$ts\n";
    }

    {
      print "* Deleting $create_num objects:\n";
      my $t0 = new Benchmark;

      my ($mung, $bar, $lexx, $kai, $brunen_g, $set, $obj_id);
      foreach (@obj_ids)
        {
          $obj_id   = $dir->delete($_);
        }

      my $t1 = new Benchmark;
      my $td = Benchmark::timediff($t1,$t0);
      my $ts = Benchmark::timestr($td);
      print "\t$ts\n";
    }

  }

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
