#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin, "$Bin/../lib";
use t_Common qw/oops btw btwN/; # strict, warnings, Carp
use t_TestCommon # Test2::V0 etc.
  qw/$silent $verbose $debug run_perlscript/;

use t_TTBUtils qw/cx2let mk_table/;

use Text::Table::Boxed;
$Text::Table::Boxed::debug = $debug;

use Data::Dumper::Interp;

{
  # The example in the SYNOPSIS
  my $tb = Text::Table::Boxed->new({
    columns => [ "Planet", "Radius\nkm", "Density\ng/cm^3" ],
    picture => <<'EOF',
┌───╥───┬───┐
│ c ║ c │ c │
╞═══╬═══╪═══╡
│ c ║ c │ c │
├───╫───┼───┤
│ c ║ c │ c │
╘═══╩═══╧═══╛
EOF
  });

  $tb->load(
    [ "Mercury", 2360, 3.7 ],
    [ "Venus", 6110, 5.1 ],
    [ "Earth", 6378, 5.52 ],
    [ "Jupiter", 71030, 1.3 ],
  );

  is($tb, <<'EOF', "SYNOPSIS example with custom picture");
┌─────────╥────────┬─────────┐
│ Planet  ║ Radius │ Density │
│         ║ km     │ g/cm^3  │
╞═════════╬════════╪═════════╡
│ Mercury ║  2360  │ 3.7     │
├─────────╫────────┼─────────┤
│ Venus   ║  6110  │ 5.1     │
├─────────╫────────┼─────────┤
│ Earth   ║  6378  │ 5.52    │
├─────────╫────────┼─────────┤
│ Jupiter ║ 71030  │ 1.3     │
╘═════════╩════════╧═════════╛
EOF
}

{
  my $tb = Text::Table::Boxed->new({
    columns => [ "Planet", "Radius\nkm", "Density\ng/cm^3" ],
    style => 'ascii'
  });

  $tb->load(
    [ "Mercury", 2360, 3.7 ],
    [ "Venus", 6110, 5.1 ],
    [ "Earth", 6378, 5.52 ],
    [ "Jupiter", 71030, 1.3 ],
  );

  is($tb, <<'EOF', "Using style=>\"ascii\"");
+----------------------------+
| Planet  | Radius | Density |
|         | km     | g/cm^3  |
+============================+
| Mercury |  2360  | 3.7     |
+---------+--------+---------+
| Venus   |  6110  | 5.1     |
+---------+--------+---------+
| Earth   |  6378  | 5.52    |
+---------+--------+---------+
| Jupiter | 71030  | 1.3     |
+----------------------------+
EOF
}

{
  my $tb = Text::Table::Boxed->new({
    columns => [ "Planet", "Radius\nkm", "Density\ng/cm^3" ],
    style => 'boxrule'
  });

  $tb->load(
    [ "Mercury", 2360, 3.7 ],
    [ "Venus", 6110, 5.1 ],
    [ "Earth", 6378, 5.52 ],
    [ "Jupiter", 71030, 1.3 ],
  );

  is($tb, <<'EOF', "Using style=>\"boxrule\"");
┌─────────┬────────┬─────────┐
│ Planet  │ Radius │ Density │
│         │ km     │ g/cm^3  │
╞═════════╪════════╪═════════╡
│ Mercury │  2360  │ 3.7     │
├─────────┼────────┼─────────┤
│ Venus   │  6110  │ 5.1     │
├─────────┼────────┼─────────┤
│ Earth   │  6378  │ 5.52    │
├─────────┼────────┼─────────┤
│ Jupiter │ 71030  │ 1.3     │
└─────────┴────────┴─────────┘
EOF
}

{
  my $tb = Text::Table::Boxed->new({
    columns => [ "Planet", "Radius\nkm", "Density\ng/cm^3" ],
    style => 'outerbox'  # Not currently documented!
  });

  $tb->load(
    [ "Mercury", 2360, 3.7 ],
    [ "Venus", 6110, 5.1 ],
    [ "Earth", 6378, 5.52 ],
    [ "Jupiter", 71030, 1.3 ],
  );

  is($tb, <<'EOF', "Using style=>\"boxrule\"");
┌────────────────────────┐
│ Planet  Radius Density │
│         km     g/cm^3  │
│ Mercury  2360  3.7     │
│ Venus    6110  5.1     │
│ Earth    6378  5.52    │
│ Jupiter 71030  1.3     │
└────────────────────────┘
EOF
}

done_testing;
