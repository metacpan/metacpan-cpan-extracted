#!perl
use strict;
use warnings;
use Test::More tests => 39;
# use Test::More 'no_plan';

BEGIN
{
   eval "use Test::Deep";
   $main::Test_Deep_loaded = $@ ? 0 : 1;
   
   $| = 1;
};


# use lib '../../../lib';
use Text::Report;

# ----------------------------- #
# --- Create new report obj --- #
# ----------------------------- #
my $rpt = Text::Report->new(debug => 'off', debugv => 1,);
   
main
{
   _test_defaults();
   
   my @data = _getdata();
   
   _build_report1(@data);
}

exit(1);


sub _build_report1
{
   my @data = @_;
   my @stuff;
   
   $stuff[0] = 'Simple Report';
   $stuff[1] = 'One 3-Dimensional Array';
   $stuff[2] = 'Pretty Average Weather Stuff';
   $stuff[3] = ' ';
   $stuff[4] = '==========';
   $stuff[5] = ' ';
   $stuff[6] = ' ';
   $stuff[7] = ' ';
   $stuff[8] = 'Solaris Host Intf Activity';
   $stuff[9] = '-------------';
   $stuff[10] = ' ';
   $stuff[11] = 'Server';
   $stuff[12] = '_______';
   $stuff[13] = 'lnc0';
   $stuff[14] = 'lnc1';
   $stuff[15] = 'lnc2';
   $stuff[16] = 'lnc3';
   $stuff[17] = 'lnc4';
   $stuff[18] = 'lnc5';
   $stuff[19] = 'lnc6';
   $stuff[20] = ' ';
   $stuff[21] = ' ';
   

   # --------------------------- #
   # --- Create Report Title --- #
   # --------------------------- #
   is(
      $rpt->defblock(name => 'title_lines', noHeaders => 1),
      $rpt,
      "Defining block \'title_lines\' with \'noHeaders\' set should return report obj");
   # Use the default report width (80 char)
   
   # --- Separate our header from the --- #
   # --- report body w/a double line  --- #
   is($rpt->insert('dbl_line'), $rpt, "Build 1st dbl_line separator should return report obj");
   
   $rpt->defblock(name => 'sd2', 
         title => $stuff[8],
         useColHeaders => 1,
         sortby => 1,
         sorttype => 'alpha',
         orderby => 'ascending',
         columnWidth => 12,
         columnAlign => 'right',
         pad => {top => 2, bottom => 2},);
   
   my $header = shift(@data);
   
   my $i = 0;
   
   # --- Place col headers from 1st line of data --- #
   for(@{$header}){$rpt->setcol('sd2', ++$i, head => $_);}
   
   $rpt->setcol('sd2', 1, align => 'left', width => 7);
   
   $rpt->fill_block('title_lines', [$stuff[0]], [$stuff[1]], [$stuff[2]],);
   
   is($rpt->fill_block('sd2', @data), $rpt, "Valid blockname should return report obj");
   is($rpt->fill_block('bla', @data), undef, "Invalid blockname should return undef");
   
   # --- Get csv data for block name 'sd2' --- #
   my @csv = $rpt->get_csv('sd2');
   
   my $x = 0;

   # --- Remove Title & Header --- #
   shift(@{$csv[0]}); shift(@{$csv[0]});
   
   # --- Check CSV data matches original data set --- #
   for(@csv)
   {
      for(@{$_})
      {
         like( $_, "/$data[$x++][0]/", "Line $x CSV data should match line $x of original data" );
      }
      
   }
   
   # --- Check that report gives us what we expect --- #
   my @report = $rpt->report('get');
   
   $x = 0;
   
   for(@report)
   {
      like( $_, "/$stuff[$x++]/i", "Line $x report data should match line $x of original data" );
   }
}


sub _test_defaults
{
   SKIP: {
      skip "Test::Deep not installed", 6 unless $main::Test_Deep_loaded;
      
      # --- Check default report width = 80 --- #
      cmp_deeply($rpt->{_page}{_profile}{report}{width}, 80, 
         "Confirming default report width = 80");
      
      # --- Check default block column width = 80 --- #
      cmp_deeply($rpt->{_block}{_profile}{_block}{column}, {1 => {width => 80, align => 'center'},}, 
         "Confirming default block column settings =  {1 => {width => 80, align => \'center\'}}");
      
      cmp_deeply($rpt->{_block}{_profile}{_block}{pad}, {top => 0, bottom => 1}, 
         "Confirming default blockPad is {top => 0, bottom => 1}");
      
      cmp_deeply($rpt->{_block}{_profile}{_block}{column}, {1 => {width => 80, align => 'center'},}, 
         "Confirming default column is 1 => {width => 80, align => \'center\'}");
         
      # --- Cols should default to using NO headers --- #
      cmp_deeply($rpt->{_block}{_profile}{_block}{useColHeaders}, 0, 
         "Confirming default useColHeaders is \"OFF\"");
      
      # --- Test column sorting properties --- #
      cmp_deeply($rpt->{_block}{_profile}{_block}{sortby}, 0, 
         "Confirming default column sort key is \"OFF\"");
   }
}

sub _getdata
{
   return(
   ['Server','Pkts Out','Bytes Out','Pkts In','Bytes In'],
   [qw(lnc0 6700730 3163758138 105780764 2526211316)],
   [qw(lnc1 332616 20424792 273036 16382160)],
   [qw(lnc2 13594464 2362497118 105780764 2526211316)],
   [qw(lnc3 312207 115266948 215356 66329648)],
   [qw(lnc4 4100 262400 4101 246060)],
   [qw(lnc5 2469926 1507952738 105780764 2526211316)],
   [qw(lnc6 503645 30218700 1811 108660)],
   );
}
