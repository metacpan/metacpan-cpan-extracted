#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 25;

BEGIN
{
   eval "use Test::Deep";
   $main::Test_Deep_loaded = $@ ? 0 : 1;
   
   eval "use Storable qw(dclone)";
   $main::stor_loaded = $@ ? 0 : 1;
   
   $| = 1;
};

# -------------------------------------- #
# --- Test our default configuration --- #
# --- and changes to global defaults --- #
# -------------------------------------- #
# use lib '../../../lib';
use Text::Report;

my $rpt = Text::Report->new(debug => 'off');



_test_defaults();

_construct($rpt);

_test_defaults();

_fill($rpt);

my @report = $rpt->report('get');

print "\n\n\n";
for(@report){print $_, "\n";}
print "\n\n\n";


my $sd1_block_obj = dclone($rpt->{_block}{_profile}{'sd1'}) if $main::stor_loaded;

is( $rpt->setblock(), undef,
      "Call setblock() with no params should return undef");

# --- Attempt to setblock() on a non-existing block_name --- #
is( $rpt->setblock(name => 'xx'), undef,
      "Set block name unknown");

is( $rpt->setblock(name => 'sd1'), $rpt,
      "Set block name sd1 with no params should return report obj");

SKIP: {
   skip "Test::Deep not installed", 1 unless ($main::Test_Deep_loaded && $main::stor_loaded);
   
   # --- sd1 was previously defined. By calling it --- #
   # --- again with no params, it's object should  --- #
   # --- remain unchanged                          --- #
   cmp_deeply($rpt->{_block}{_profile}{'sd1'}, $sd1_block_obj,
      "Block object \'sd1\' should remain unchanged");
}

is( $rpt->setblock(name => 'sd1', useColHeaders => 0,), $rpt,
      "Setting block name sd1 with useColHeaders to \"OFF\" should return report obj");

# --- Clear data, change useColHeaders param --- #
$rpt->clr_block_data('sd1');
$rpt->clr_block_headers('sd1');
$rpt->fill_block('sd1', ['14','22:05','Calm','10','ONLYLINE','CLR','63','61','30.08','NA']);


SKIP: {
   skip "Test::Deep not installed", 1 unless $main::Test_Deep_loaded;
   
   cmp_deeply($rpt->{_block}{_profile}{'sd1'}{useColHeaders}, 0,
      "Block object \'sd1\' should have useColHeaders set to \"OFF\"");
}

# --- Ensure that the defaults remain unchanged --- #
_test_defaults();

@report = ();

@report = $rpt->report('get');

print "\n\n\n";
for(@report){print $_, "\n";}
print "\n\n\n";




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
sub _construct
{
   my $rpt = shift;
   
   # --- , useColHeaders => 0 # DEFAULT --- #
   $rpt->defblock(name => 'title_lines');
   $rpt->insert('dbl_line');
   
   is( 
   # --- Create a block & confirm that all --- #
   # --- of the defaults remain unchanged  --- #
   $rpt->defblock(name => 'sd1', 
         column =>
         {
               1 => {width => 4, align => 'left', head => 'Date'},
               2 => {width => 5, align => 'left', head => 'Time'},
               3 => {width => 6, align => 'left', head => 'Wind'},
               4 => {width => 7, align => 'left', head => 'Vis'},
               5 => {width => 15, align => 'left', head => 'Cond'},
               6 => {width => 7, align => 'left', head => 'Sky'},
               7 => {width => 4, align => 'left', head => 'Air'},
               8 => {width => 4, align => 'left', head => 'Dwpt'},
         },
         useColHeaders => 1,
         title => 'Solar Surface Activity',
         sortby => 1,
         sorttype => 'numeric',
         orderby => 'descending',), $rpt,
         
         "Creating new report block with valid params\'sd1\'"
   );
   
   $rpt->insert('dbl_line');
   $rpt->defblock(name => 'footer', useColHeaders => 0);
}

sub _fill
{
   my $rpt = shift;
   
   # --- Once data has been assigned to a block, parameters --- #
   # --- may still be changed using setblock(), however the --- #
   # --- format of the existing data will remain unchanged. --- #
   # --- In order to implement the new params, the methods  --- #
   # --- clr_block_data() & clr_block_headers() must be     --- #
   # --- called w/the appropriate block name.               --- #
   $rpt->fill_block('title_lines', ['First Title Line Using Block Defaults'], ['Second Title Line'],);
   $rpt->fill_block('footer', ['Full-Duplex Communications, Inc.'], ['Florida Design Engineering']);
   
   my @blocks = qw(sd1 sd2 sd3 sd4);
   
   while(<DATA>){chomp; for my $bn(@blocks){$rpt->fill_block($bn, [split(',')]);}}
   
}

__DATA__
14,22:05,Calm,10,FIRSTLINE,CLR,63,61,30.08,NA
13,21:45,NE 3,10,Fair,CLR,63,61,30.08,NA
13,21:25,Calm,10,Fair,CLR,64,63,30.09,NA
12,21:05,E 5,11,Fair,CLR,64,62,30.08,NA
12,20:45,E 5,10,Fair,CLR,64,63,30.09,NA
12,20:25,E 6,10,Fair,CLR,64,63,30.09,NA
11,20:05,E 7,10,Partly Cloudy,SCT075,64,63,30.09,NA
11,19:45,E 5,12,Partly Cloudy,SCT075,66,63,30.1,NA
11,19:25,E 6,10,Partly Cloudy,SCT075,66,63,30.09,NA
11,19:05,E 6,15,Heavy Rain,OVC075,68,68,30.09,NA
11,18:45,E 6,14,Rain,OVC065,68,67,30.1,NA
11,18:25,E 7,18,Lt Rain,OVC065,68,67,30.11,NA
10,18:05,E 5,10,Overcast,OVC065,68,66,30.11,NA
10,17:45,E 6,10,Overcast,OVC065,68,63,30.11,NA
10,17:25,SE 7,10,Overcast,OVC055,70,61,30.11,NA
10,17:05,E 8,10,Overcast,OVC055,70,61,30.11,NA
10,16:45,E 8,04,Overcast,OVC055,70,61,30.1,NA
10,16:25,E 8,10,Overcast,OVC065,70,59,30.1,NA
10,16:05,E 9,13,Overcast,OVC065,72,59,30.1,NA
10,15:45,E 9,12,Overcast,OVC065,72,61,30.1,NA
9,15:25,E 8,10,Mostly Cloudy,BKN065,70,61,30.11,NA
9,15:05,E 6,10,Overcast,OVC065,70,63,30.11,NA
9,14:45,E 10,10,Sprinkles,OVC075,70,67,30.12,NA
9,14:25,E 9,08,Overcast,OVC070,70,65,30.12,NA
9,14:15,E 9,08,Overcast,OVC070,70,61,30.12,NA
9,14:05,E 9,08,Overcast,OVC070,70,61,30.12,NA
8,14:04,E 9,08,Overcast,OVC070,70,61,30.12,NA
8,14:03,E 9,08,Overcast,OVC070,70,61,30.12,NA
7,14:02,E 9,08,LASTLINE,CLR070,74,61,30.15,NA