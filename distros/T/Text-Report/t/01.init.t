#!perl
use strict;
use warnings;
use Test::More tests => 30;
# use Test::More 'no_plan';

BEGIN
{
   eval "use Test::Deep";
   $main::Test_Deep_loaded = $@ ? 0 : 1;
   
   eval "use Storable qw(dclone)";
   $main::stor_loaded = $@ ? 0 : 1;
   
   $| = 1;
};

# use lib '../../../lib';
use Text::Report;

# --------------------------------- #
# --- Test our opt dependencies --- #
# --------------------------------- #
# 2
use_ok('Storable', qw(store retrieve dclone));
use_ok('Carp');



SKIP:
{
   skip( 'tmp checks; Not used w/o Storable', 2 ) unless $main::stor_loaded;
   
   # Test existence of /tmp
   is( -e '/tmp', 1, "/tmp should exist");
   # Test create rights in /tmp
   is((open F, "+>/tmp/__reporttest.tmp"), 1, "/tmp should be writable");
   is((grep{unlink} '/tmp/__reporttest.tmp'), 1, "/tmp/file should be removable");
   close F;
}

my $rpt = Text::Report->new(debug => 'off', debugv => 1);

# --- Test our obj   --- #
# 1
ok( defined($rpt) && ref $rpt eq 'Text::Report', "new() Obj and Class OK");

SKIP: {
   skip "Test::Deep not installed", 1 unless $main::Test_Deep_loaded;
   
   cmp_deeply($rpt->{_debug}, {_verbose => 1, _lev => 0});
}

# --------------------------------------- #
# --- Test methods - Public           --- #
# --------------------------------------- #
# 16
my @methods = qw
   (new configure defblock setblock setcol 
   insert fill_block report get_csv rst_block 
   del_block clr_block_data clr_block_headers
   named_blocks linetypes AUTOLOAD);

foreach my $meth (@methods) {can_ok($rpt, $meth)
   || print "Report cant do $meth()";}

# --------------------------------------- #
# --- Test methods - private          --- #
# --------------------------------------- #
# 7

@methods = qw
   (_sort _draw_line _debug _numeric _assign_def_block
   _default_block _default_report);

foreach my $meth (@methods) {can_ok($rpt, $meth)
   || print "Report cant do $meth()";}

