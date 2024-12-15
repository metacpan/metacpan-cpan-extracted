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

# Preliminary test using rules with all-different characters 
{ my $tb = Text::Table::Boxed->new({ columns => ["aaa","bbb"],
                                     picture => <<'EOF'
(*%!)
c | c
<@^=>
EOF
                                    });
  $tb->add("aaaval","bv");
  is($tb->table(0,1), "aaa    | bbb\n", "table(0,1)");
  is($tb->table(1,1), "aaaval | bv \n", "table(1,1)");
  is($tb->top_rule(), "((((((*%!)))\n", "top_rule");
  is($tb->bot_rule(), "<<<<<<@^=>>>\n", "bot_rule");
  is($tb->title(), "aaa    | bbb\n", "title");
  is($tb->rendered_title(), <<'EOF', "rendered_title");
((((((*%!)))
aaa    | bbb
<<<<<<@^=>>>
EOF
  is($tb->rendered_title_height(), 3, "rendered_title_height");
  is([$tb->rows(0,1)], [["aaa    | bbb\n"]], "rows(0,1)");
  is([$tb->rows(0,2)], [ ["aaa    | bbb\n"], ["aaaval | bv \n"] ], "rows(0,2)");
  is([$tb->body_rows(0,1)], [ ["aaaval | bv \n"] ], "body_rows(0,1)");
  is([$tb->rendered_body_rows(0,1)], 
     [ ["aaaval | bv \n", "<<<<<<@^=>>>\n"] ], "rendered_body_rows(0,1)");
  is($tb, <<EOF, "stringify special table");
((((((*%!)))
aaa    | bbb
aaaval | bv\x{20}
<<<<<<@^=>>>
EOF
  is($tb->rendered_table_height(), 4, "rendered_table_height");
}

{ my $num_body_rows = 1;
  for my $num_pic_cols (2..5) {
    for my $num_pic_rows(2..5) {
      my $tb = mk_table(num_body_rows => $num_body_rows,
                        num_data_cols => 2, 
                        num_pic_cols => $num_pic_cols, 
                        num_pic_rows => $num_pic_rows);
      #print "PICTURE:\n", @{ $tb->{Text::Table::Boxed::MYKEY()}->{picture} },"\n";
      my $aftertitle = "+TTTTTTTTTT+TTTTTTTTTTTTTTTTTT+";
      $aftertitle =~ s/T/m/g if $num_pic_rows <= 2;
      is($tb, <<EOF, "nbr=1 ndc=2 num_pic_cols=$num_pic_cols _rows=$num_pic_rows")
[----------+------------------]
| Title-A1 | Title-A2         |
$aftertitle
| Data-B1  | Data-B2          |
|          | extra wide line2 |
<bbbbbbbbbb+bbbbbbbbbbbbbbbbbb>
EOF
   }
  }

  for my $num_pic_cols (3..8) {
    for my $num_pic_rows(2..8) {
      my $tb = mk_table(num_body_rows => $num_body_rows,
                        num_data_cols => 5, 
                        num_pic_cols => $num_pic_cols, 
                        num_pic_rows => $num_pic_rows);
      my $aftertitle = "+TTTTTTTTTT+TTTTTTTTTTTTTTTTTT+TTTTTTTTTT+TTTTTTTTTT+TTTTTTTTTT+";
      $aftertitle =~ s/T/m/g if $num_pic_rows <= 2;
      is($tb, <<EOF, "nbr=1 ndc=5 num_pic_cols=$num_pic_cols _rows=$num_pic_rows")
[----------+------------------+----------+----------+----------]
| Title-A1 | Title-A2         | Title-A3 | Title-A4 | Title-A5 |
$aftertitle
| Data-B1  | Data-B2          | Data-B3  | Data-B4  | Data-B5  |
|          | extra wide line2 | line2    | line2    | line2    |
|          |                  | line3    | line3    | line3    |
|          |                  |          | line4    | line4    |
|          |                  |          |          | line5    |
<bbbbbbbbbb+bbbbbbbbbbbbbbbbbb+bbbbbbbbbb+bbbbbbbbbb+bbbbbbbbbb>
EOF
    }
  }
}

{ my $tb = Text::Table::Boxed->new();
  is($tb, "", "empty table");
}

{ my $tb = mk_table(num_body_rows => 0, num_data_cols => 3, num_pic_cols => 3);
  #print "PICTURE:\n", @{ $tb->{Text::Table::Boxed::MYKEY()}->{picture} },"\n";
  is($tb, <<'EOF', "zaro body rows");
[----------+----------+----------]
| Title-A1 | Title-A2 | Title-A3 |
<bbbbbbbbbb+bbbbbbbbbb+bbbbbbbbbb>
EOF
}

done_testing;
