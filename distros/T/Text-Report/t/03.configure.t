#!perl
use strict;
use warnings;
# use Test::More 'no_plan';
use Test::More tests => 22;

BEGIN
{
   eval "use Test::Deep";
   $main::Test_Deep_loaded = $@ ? 0 : 1;
   
   $| = 1;
};

# -------------------------------------- #
# --- Test our default configuration --- #
# --- and changes to global defaults --- #
# -------------------------------------- #
# use lib '../../../lib';
use Text::Report;

my $rpt = Text::Report->new(debug => 'off', debugv => 1);

_test_defaults();

is( $rpt->configure, undef, 
   "Calling configure() with no params should return undef");

# ------------------------------------- #
# --- Test debug level & carp level --- #
# ------------------------------------- #
is( $rpt->configure(debugv => 0, debug => 'notice'), $rpt, 
   "Setting debug level to \'notice\' and verbose off should return report obj");

SKIP: {
   skip "Test::Deep not installed", 1 unless $main::Test_Deep_loaded;
         
   cmp_deeply($rpt->{_debug}, {_verbose => 0, _lev => 1}, 
      "Debug level should be set to 1 and verbose off");
}

# --- Be kind --- #
$rpt->configure(debugv => 0, debug => 'off');

# ------------------ #
# --- Test width --- #
# ------------------ #
is( $rpt->configure(width => 120), $rpt, 
      "Setting default block col width = 120");

SKIP: {
   skip "Test::Deep not installed", 2 unless $main::Test_Deep_loaded;
     
   cmp_deeply($rpt->{_page}{_profile}{report}{width}, 120, 
      "Default report width should = 120");
   
   # ------------------------------------------- #
   # --- Remember, changing report width     --- #
   # --- $rpt->configure(width => 120) also  --- #
   # --- changes the default block col width --- #
   # ------------------------------------------- #

   # --- Confirm effect of report width change on default col width --- #
   cmp_deeply($rpt->{_block}{_profile}{_block}{column}, {1 => {width => 120, align => 'center'},}, 
      "Default block column width should = 120");
}

# --------------------- #
# --- Test blockPad --- #
# --------------------- #  Defaults {top => 0, bottom => 1} --- #
is( $rpt->configure(blockPad => 3), undef, 
      "Calling configure(blockPad) with bad params should return undef");

is( $rpt->configure(blockPad => {top => 2, bottom => 2}), $rpt, 
      "Setting blockPad to {top => 2, bottom => 2}");

SKIP: {
   skip "Test::Deep not installed", 1 unless $main::Test_Deep_loaded;
   
   cmp_deeply($rpt->{_block}{_profile}{_block}{pad}, {top => 2, bottom => 2}, 
      "Default blockPad should now be {top => 2, bottom => 2}");
}

# ------------------- #
# --- Test column --- #
# ------------------- #
is( $rpt->configure(column => 3), undef, 
   "Calling configure(column) with bad params should return undef");

# --- Change default block column width settings --- #
is( $rpt->configure(column => {1 => {width => 40, align => 'right'},}), $rpt, 
      "Setting default column params to {1 => {width => 40, align => 'right'}} should return report obj");
      
# use Data::Dumper; print Dumper $rpt; <STDIN>;

SKIP: {
   skip "Test::Deep not installed", 2 unless $main::Test_Deep_loaded;
     
   # --- Check block column settings --- #
   cmp_deeply($rpt->{_block}{_profile}{_block}{column}, {1 => {width => 40, align => 'right'},}, 
      "Default column should now be {1 => {width => 40, align => \'right\'}}");
   
   # --- Confirm report width settings have not changed --- #
   cmp_deeply($rpt->{_page}{_profile}{report}{width}, 120, 
      "Default report width should remain unchanged at 120");
}

# -------------------------- #
# --- Test useColHeaders --- #
# -------------------------- #
is( $rpt->configure(useColHeaders => 1), $rpt,
   "Setting useColHeaders to TRUE should return report obj");

# -------------------------- #
# --- Test sortby        --- #
# -------------------------- #
is( $rpt->configure(sortby => 2), $rpt,
   "Setting default column sort key to column two should return report obj");

SKIP: {
   skip "Test::Deep not installed", 1 unless $main::Test_Deep_loaded;
     
   cmp_deeply($rpt->{_block}{_profile}{_block}{sortby}, 2, 
      "Default column sort key should be set to column 2");
}

sub _test_defaults
{
   SKIP: {
      skip "Test::Deep not installed", 6 unless $main::Test_Deep_loaded;
      
      # --- Check default report width = 80 --- #
      cmp_deeply($rpt->{_page}{_profile}{report}{width}, 80, 
         "Default report width should = 80");
      
      # --- Check default block column width = 80 --- #
      cmp_deeply($rpt->{_block}{_profile}{_block}{column}, {1 => {width => 80, align => 'center'},}, 
         "Default block column settings should =  {1 => {width => 80, align => \'center\'}}");
      
      cmp_deeply($rpt->{_block}{_profile}{_block}{pad}, {top => 0, bottom => 1}, 
         "Default blockPad should be {top => 0, bottom => 1}");
      
      cmp_deeply($rpt->{_block}{_profile}{_block}{column}, {1 => {width => 80, align => 'center'},}, 
         "Default column should be 1 => {width => 80, align => \'center\'}");
         
      # --- Cols should default to using NO headers --- #
      cmp_deeply($rpt->{_block}{_profile}{_block}{useColHeaders}, 0, 
         "Default useColHeaders should be \"OFF\"");
      
      # --- Test column sorting properties --- #
      cmp_deeply($rpt->{_block}{_profile}{_block}{sortby}, 0, 
         "Default column sort key should be \"OFF\"");
   }
}

