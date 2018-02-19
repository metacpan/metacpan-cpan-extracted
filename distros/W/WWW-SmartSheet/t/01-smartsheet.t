use strict;
use warnings;

use Data::Dumper;

use Test::More;
use Test::Deep;

my $msg;
my $token = $ENV{TOKEN};
diag "TOKEN: $token" if defined $token;
plan skip_all => 'Works only if API token provided in he TOKEN environment variable'
	if not $token;

plan tests => 15;

my $sheet_id;

if ($ENV{"SHEET"}) {
  $sheet_id = $ENV{"SHEET"};
}

use WWW::SmartSheet;
my $w = WWW::SmartSheet->new( token => $token );

# Test #1 - is $w a WWW:::SmartSheet class?
isa_ok($w, 'WWW::SmartSheet');

# Test #2 - get_current_user
my %current_user = %{$w->get_current_user};
diag "Current User: ". $current_user{"firstName"} . " " . $current_user{"lastName"} . "(" . $current_user{"id"} . ")";
ok($current_user{"id"} =~ m/[0-9]/, "Current User Id is numeric");

# Test #3 - create_sheet
SKIP: {
  if (!$current_user{"licensedSheetCreator"}) {
    diag "NO CREATE PERMISSION - skipping create test";
    skip "NO CREAT PERMISSION", 1;
  }

  if ($sheet_id) {
    diag "SHEET ID SET - skipping create test";
    skip "SHEET ID SET - skipping create test", 1;
  }
  
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  $mon++;
  $year += 1900;
  my $date = sprintf("%04d-%02d-%02d", $year, $mon, $mday);
  my $time = sprintf("%02d:%02d:%02d", $hour, $min, $sec);
  my $sheet_name = "New Test Sheet ($date $time)";
  note "creating sheet with name, $sheet_name";

  my @cols = [
	      {"title" => "My first primary Col txtnum",
	       "type" => "TEXT_NUMBER",
	       "primary" => 1,
	      },
	      {"title" => "My second Col contacts",
	       "type" => "CONTACT_LIST",
	      },
	      {"title" => "Third Col - chkbx",
	       "type" => "CHECKBOX",
	       "symbol" => "FLAG",
	      },
	      {"title" => "Forth Col - pick",
	       "type" => "PICKLIST",
	       "options" => ["OptA", "Opt B", "Third choice"],
	      },
	     ];

  my %result = %{$w->create_sheet("name" => $sheet_name, "columns" => @cols)};

  # assuming the API knows if it is successful or not, instead of checking the sheet
  ok($result{"message"} eq "SUCCESS", "Sheet successfully created");
  $sheet_id = $result{"result"}{"id"};

  diag "Sheet id: $sheet_id";

  # @cols_in_sheet = @{$result{"result"}{"columns"}}; # to compare with what we get from get_columns;

}

if (!$sheet_id) {

  BAIL_OUT("No sheet id. Can't continue");

}

# Test #4 - get_sheets
my %all_sheets = %{$w->get_sheets()};

if ($all_sheets{"totalCount"} == 0) {
  BAIL_OUT("No sheets listed! Can't continue!");
}

my $pass_get_sheets;
foreach my $s (@{$all_sheets{"data"}}) {
  if ($s->{"id"} eq "$sheet_id") {
    note $s->{"id"} . " is an available sheet";
    $pass_get_sheets = 1;
  }
}

ok($pass_get_sheets == 1, "get_sheets got $sheet_id");

# Test #5 - add_column

my @cols = [
	    {"title" => "New Picklist Column 1", "type" => "PICKLIST", "options" => ["First", "Second", "Third"], "index" => 2},
	    {"title" => "New Date Column", "type" => "DATE", "validation" => 1, "index" => 2},
	   ];

my %ac_result = %{$w->add_column($sheet_id, @cols)};
note Dumper \%ac_result;
ok($ac_result{"message"} eq "SUCCESS", "add_column");

# Test #6 -  get_columns

my %cols = %{$w->get_columns($sheet_id)};
note Dumper \%cols;
ok($cols{"totalCount"} > 0, "Sheet has more than zero columns");


# Stuff for Insert Rows Tests

my @cols_in_sheet;
push(@cols_in_sheet, @{$cols{"data"}});
note Dumper \@cols_in_sheet;

my $q = 0; # absolute new row counter

sub mk_new_rows {
  # creates row array with two rows, or whatever number given

  my $num_rows;

  if (@_) {
    $num_rows = shift;
  } else {
    $num_rows = 2;
  }

  $q++;
  my $i = 0; # column counter
  my @new_rows;

  # print Dumper \@new_rows;

  for (my $j=0; $j < $num_rows; $j++) {

    $i = 0;

    foreach my $co (@cols_in_sheet) {

      note "I:$i, J:$j";

      my %c = %{$co};

      if ($c{"type"} eq "CONTACT_LIST") { next;}

      note $c{"id"} . " " .  $c{"type"} . " " . $c{"title"} . "\n";

      if ($c{"type"} eq "TEXT_NUMBER") {

	$new_rows[$j][$i]->{"columnId"} = $c{"id"};
	$new_rows[$j][$i]->{"value"} = "New Row (Q:$q, I:$i, J:$j)";

      } elsif ($c{"type"} eq "CHECKBOX") {
	$new_rows[$j][$i]->{"columnId"} = $c{"id"};
	if ($j % 2 == 0) {
	  $new_rows[$j][$i]->{"value"} = JSON::true;
	} else {
	  $new_rows[$j][$i]->{"value"} = JSON::false;
	}

      } elsif ($c{"type"} eq "PICKLIST") {

	$new_rows[$j][$i]->{"columnId"} = $c{"id"};
	$new_rows[$j][$i]->{"value"} = $c{"options"}->[$j % scalar(@{$c{"options"}})];

      } else {
	note "UNKNOWN COL SKIPPING";
	next;
      }

      note "NEW ROWS IN COL LOOP";
      note Dumper \@new_rows;

      $i++;

    }

    note "NEW ROWS IN ROW LOOP";
    note Dumper \@new_rows;

  }

  return @new_rows;

}

# for the insert_rows tests, ideally we'd check to make sure things
# were inserted in the correct location.  However we're going to just
# assuming if the API says success that things got where they should.

# Test #7 - insert_rows toTop
my @nr = mk_new_rows("1");
note Dumper \@nr;

my %i_result = %{$w->insert_rows($sheet_id, "toTop", @nr)};
ok($i_result{"message"} eq "SUCCESS", "Insert Row toTop in a likely empty sheet");

my $num_inserted_rows = scalar(@{$i_result{"result"}});
note "NUM_INSERTED_ROWS: $num_inserted_rows";
my $base_row = $i_result{"result"}->[0]->{"id"};
note "BASE ROW: $base_row";

# Test #8 - insert_rows toTop (of just inserted rows)
@nr = mk_new_rows("3");
note Dumper \@nr;
%i_result = %{$w->insert_rows($sheet_id, "toTop", @nr)};
ok($i_result{"message"} eq "SUCCESS", "Insert Row toTop");
$num_inserted_rows = scalar(@{$i_result{"result"}});
note "NUM_INSERTED_ROWS: $num_inserted_rows";

# Test #9 - insert_rows toBottom
@nr = mk_new_rows("3");
note Dumper \@nr;
%i_result = %{$w->insert_rows($sheet_id, "toBottom", @nr)};
ok($i_result{"message"} eq "SUCCESS", "Insert Row toBottom");
$num_inserted_rows = scalar(@{$i_result{"result"}});
note "NUM_INSERTED_ROWS: $num_inserted_rows";

# Test #10 - insert_rows parentId
@nr = mk_new_rows("2");
note Dumper \@nr;
%i_result = %{$w->insert_rows($sheet_id, "parentId=$base_row", @nr)};
ok($i_result{"message"} eq "SUCCESS", "Insert Row parentId=$base_row");
$num_inserted_rows = scalar(@{$i_result{"result"}});
note "NUM_INSERTED_ROWS: $num_inserted_rows";

# Test #11 - insert_rows sibblingId
@nr = mk_new_rows("1");
note Dumper \@nr;
%i_result = %{$w->insert_rows($sheet_id, "siblingId=$base_row", @nr)};
ok($i_result{"message"} eq "SUCCESS", "Insert Row siblingId=$base_row");
$num_inserted_rows = scalar(@{$i_result{"result"}});
note "NUM_INSERTED_ROWS: $num_inserted_rows";

# Test #12 - insert_rows sibblingId above
@nr = mk_new_rows("1");
note Dumper \@nr;
%i_result = %{$w->insert_rows($sheet_id, "siblingId=$base_row,above", @nr)};
ok($i_result{"message"} eq "SUCCESS", "Insert Row siblingId=$base_row,above");
$num_inserted_rows = scalar(@{$i_result{"result"}});
note "NUM_INSERTED_ROWS: $num_inserted_rows";

# Test #13 - get_sheet_by_id
my $pagesize = 1;
my $page = 1;
# only getting the first row
my %sheet = %{$w->get_sheet_by_id($sheet_id, $pagesize, $page)};
note Dumper \%sheet;
ok(!$sheet{"errorCode"}, "get_sheet_by_id"); # if no errorCode it's all good 

SKIP: {
 # Test #14 - share_sheet  
   skip "NO SHARE ADDRESS GIVEN", 1 if (!$ENV{"SHAREWITH"});
   diag "Giving VIEWER permissions to " . $ENV{"SHAREWITH"};
   my $access_lvl = "VIEWER";
   my %result = %{$w->share_sheet($sheet_id, $ENV{"SHAREWITH"}, $access_lvl)};

   ok($result{"message"} eq "SUCCESS", "sharing sheet");

   note Dumper \%result;

}

SKIP: {
  # Test #15 -  delete_sheet
  if ($ENV{"SKIPDELETE"}) {
    diag "sheet $sheet_id not deleted";
    skip "SKIP DELETE REQUESTED", 1;
  }

  my %d_result = %{$w->delete_sheet($sheet_id)};

  note Dumper \%d_result;

  ok($d_result{"message"} eq "SUCCESS", "delete sheet");

}

done_testing();
