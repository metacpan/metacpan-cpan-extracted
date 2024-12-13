#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin, "$Bin/../lib";
use t_Common qw/oops btw btwN/; # strict, warnings, Carp
use t_TestCommon # Test2::V0 etc.
  qw/$silent $verbose $debug run_perlscript/;

use t_TTBUtils qw/cx2let mk_table/;

use Text::Table::Boxed::Pager qw/view_table paginate_table/;

use Getopt::Long qw/GetOptions/;
Getopt::Long::Configure("default");
my ($interactive, $dump_bigtable);
my $bigtable_rows = 20;
GetOptions(
  "i|interactive"   => \$interactive,
  "dump-bigtable"   => \$dump_bigtable,
  "num-rows=i"      => \$bigtable_rows,
) or die "died";

{
  # PAGENATE - exactly one row per page (plus repeated title)
  # 3 lines for top_rule + title + aftert_rule
  # 3 lines for a 3-line row
  # 1 line for after-row mid_rule
  # ------
  # 7 lines minimum to fit a row per page
  my $tb = mk_table(num_data_cols => 3, num_body_rows => 4);
  my $text = paginate_table($tb, lines_per_page => 7);
  is($text, <<EOF, "paginate_table, exactly 1 row per page");
[----------+------------------+----------]
| Title-A1 | Title-A2         | Title-A3 |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+
| Data-B1  | Data-B2          | Data-B3  |
|          | extra wide line2 | line2    |
|          |                  | line3    |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+
\f[----------+------------------+----------]
| Title-A1 | Title-A2         | Title-A3 |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+
| Data-C1  | Data-C2          | Data-C3  |
|          | extra wide line2 | line2    |
|          |                  | line3    |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+
\f[----------+------------------+----------]
| Title-A1 | Title-A2         | Title-A3 |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+
| Data-D1  | Data-D2          | Data-D3  |
|          | extra wide line2 | line2    |
|          |                  | line3    |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+
\f[----------+------------------+----------]
| Title-A1 | Title-A2         | Title-A3 |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+
| Data-E1  | Data-E2          | Data-E3  |
|          | extra wide line2 | line2    |
|          |                  | line3    |
<bbbbbbbbbb+bbbbbbbbbbbbbbbbbb+bbbbbbbbbb>
EOF
}

{
  # PAGENATE - exactly two rows per page (plus repeated title)
  # 3 lines for top_rule + title + aftert_rule
  # 3 lines for a 3-line row
  # 1 line for after-row mid_rule
  # 3 lines for a 3-line row
  # 1 line for after-row mid_rule
  # ------
  # 11 lines minimum to fit two rows per page
  my $tb = mk_table(num_data_cols => 3, num_body_rows => 4);
  my $text = paginate_table($tb, lines_per_page => 11);
  is($text, <<EOF, "paginate_table, exactly 2 rows per page");
[----------+------------------+----------]
| Title-A1 | Title-A2         | Title-A3 |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+
| Data-B1  | Data-B2          | Data-B3  |
|          | extra wide line2 | line2    |
|          |                  | line3    |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+
| Data-C1  | Data-C2          | Data-C3  |
|          | extra wide line2 | line2    |
|          |                  | line3    |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+
\f[----------+------------------+----------]
| Title-A1 | Title-A2         | Title-A3 |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+
| Data-D1  | Data-D2          | Data-D3  |
|          | extra wide line2 | line2    |
|          |                  | line3    |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+
| Data-E1  | Data-E2          | Data-E3  |
|          | extra wide line2 | line2    |
|          |                  | line3    |
<bbbbbbbbbb+bbbbbbbbbbbbbbbbbb+bbbbbbbbbb>
EOF
}

{
  # PAGENATE - one row per page with extra space
  # 3 lines for top_rule + title + aftert_rule
  # 3 lines for a 3-line row
  # 1 line for after-row mid_rule
  # ------
  # 7 lines minimum to fit one row + title
  my $tb = mk_table(num_data_cols => 3, num_body_rows => 4);
  my $text = paginate_table($tb, lines_per_page => 10);
  is($text, <<EOF, "paginate_table, 1 row per page + 3 extra lines");
[----------+------------------+----------]
| Title-A1 | Title-A2         | Title-A3 |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+
| Data-B1  | Data-B2          | Data-B3  |
|          | extra wide line2 | line2    |
|          |                  | line3    |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+



\f[----------+------------------+----------]
| Title-A1 | Title-A2         | Title-A3 |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+
| Data-C1  | Data-C2          | Data-C3  |
|          | extra wide line2 | line2    |
|          |                  | line3    |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+



\f[----------+------------------+----------]
| Title-A1 | Title-A2         | Title-A3 |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+
| Data-D1  | Data-D2          | Data-D3  |
|          | extra wide line2 | line2    |
|          |                  | line3    |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+



\f[----------+------------------+----------]
| Title-A1 | Title-A2         | Title-A3 |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+
| Data-E1  | Data-E2          | Data-E3  |
|          | extra wide line2 | line2    |
|          |                  | line3    |
<bbbbbbbbbb+bbbbbbbbbbbbbbbbbb+bbbbbbbbbb>
EOF
}

{
  # PAGENATE - one row per page with exactly one extra line 
  # 3 lines for top_rule + title + aftert_rule
  # 3 lines for a 3-line row
  # 1 line for after-row mid_rule
  # ------
  # 7 lines minimum to fit one row + title
  my $tb = mk_table(num_data_cols => 3, num_body_rows => 4);
  my $text = paginate_table($tb, lines_per_page => 8, fill_last_page => 1);
  is($text, <<EOF, "paginate_table, 1 row per page + exactly one line, fill_last_page");
[----------+------------------+----------]
| Title-A1 | Title-A2         | Title-A3 |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+
| Data-B1  | Data-B2          | Data-B3  |
|          | extra wide line2 | line2    |
|          |                  | line3    |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+

\f[----------+------------------+----------]
| Title-A1 | Title-A2         | Title-A3 |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+
| Data-C1  | Data-C2          | Data-C3  |
|          | extra wide line2 | line2    |
|          |                  | line3    |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+

\f[----------+------------------+----------]
| Title-A1 | Title-A2         | Title-A3 |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+
| Data-D1  | Data-D2          | Data-D3  |
|          | extra wide line2 | line2    |
|          |                  | line3    |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+

\f[----------+------------------+----------]
| Title-A1 | Title-A2         | Title-A3 |
+mmmmmmmmmm+mmmmmmmmmmmmmmmmmm+mmmmmmmmmm+
| Data-E1  | Data-E2          | Data-E3  |
|          | extra wide line2 | line2    |
|          |                  | line3    |
<bbbbbbbbbb+bbbbbbbbbbbbbbbbbb+bbbbbbbbbb>

EOF
}

if ($dump_bigtable) {
  my $tb = mk_table(num_data_cols => 3, num_body_rows => $bigtable_rows);
  print $tb;
}

SKIP: {
  unless ($interactive) {
    skip "Only with --interactive on terminal"
  }
  ######################################################
  # Demo the pager
  ######################################################
  my $tb = mk_table(num_data_cols => 3, num_body_rows => 200);
  my $result = view_table($tb);
  pass("view_table returned ".vis($result));
}

done_testing();
