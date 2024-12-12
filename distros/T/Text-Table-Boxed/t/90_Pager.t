#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin, "$Bin/../lib";
use t_Common qw/oops btw btwN/; # strict, warnings, Carp
use t_TestCommon # Test2::V0 etc.
  qw/$silent $verbose $debug run_perlscript/;

use t_TTBUtils qw/cx2let mk_table/;

use Text::Table::Boxed::Pager qw/view_table/;

skip_all("Only with --interactive argument") 
  unless @ARGV && $ARGV[0] =~ /^--?i/;
oops "too many args" if @ARGV > 1;

######################################################
# Demo of the pager 
######################################################

my $tb = mk_table(num_data_cols => 3, num_body_rows => 200);

my $result = view_table($tb);

pass("view_table returned ".vis($result));
done_testing();

