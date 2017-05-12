######################################################################
# Test suite for X10::Home
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;

use X10::Home;
use Test::More;
use File::Temp qw(tempdir);

plan tests => 4;

SKIP: {
  skip "No /dev/ttyS0 found", 4 unless -e "/dev/ttyS0";

  my($dir) = tempdir(CLEANUP => 1);
  
  my $eg = "eg";
  $eg = "../eg" unless -d $eg;
  
  my $x = X10::Home->new(
      conf_file => "$eg/x10.conf",
      db_file   => "$dir/foo",
      probe     => 0,
  );
  
  $x->db_status("foo", "bar");
  is($x->db_status("foo"), "bar", "Storing status in DB");
  
  $x->db_status("foo", "baz");
  is($x->db_status("foo"), "baz", "Storing status in DB");
  
    # dbmclose
  undef $x;
  
    # re-init
  $x = X10::Home->new(
      conf_file => "$eg/x10.conf",
      db_file   => "$dir/foo",
      probe     => 0,
  );
  
  is($x->db_status("foo"), "baz", "Retrieved persistent status");
  
  $x->db_status("foo", "bar");
  
    # dbmclose
  undef $x;
  
    # re-init
  $x = X10::Home->new(
      conf_file => "$eg/x10.conf",
      db_file   => "$dir/foo",
      probe     => 0,
  );
  
  is($x->db_status("foo"), "bar", "Retrieved persistent status");
}
