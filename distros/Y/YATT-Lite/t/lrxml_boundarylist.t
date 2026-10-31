#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#
# GH-258: _boundarylist (宣言/コメントの位置記録) の構造の表明。
#
#  - parse_decl は全ての <!ns:kind ...> 宣言と <!--#ns ... --> コメントの
#    先頭/末尾 pos を $tmpl->{_boundarylist} に記録する
#  - 不変量: substr($string, startpos, endpos - startpos) はその構文要素の全文
#  - source_substr ベース part (entity/action) の本体は part_body_source で
#    取り出し、区間内のコメント span は同じ改行数の \n 列に置換される
#
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::Kantan;

use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite;

my $template = <<'END';
leading [&yatt:e1();]
<!yatt:widget w1 x>
w1 body &yatt:x;
<!yatt:entity e1>
my $v = "E1";
<!--#yatt
<!yatt:widget disabled>
#-->
$v;
<!yatt:argmacro m1=[x]>
$result->{x} = "m1";

<!yatt:widget w2 %m1;>
w2 x=&yatt:x;
END

my $yatt = YATT::Lite->new(
  app_ns => "TestBoundaryList",
  vfs => [data => {index => $template}],
);

my ($tmpl) = $yatt->get_vfs->find_file('index');
$yatt->find_product(perl => $tmpl);

describe "_boundarylist", sub {
  my $list = $tmpl->{_boundarylist};

  it "should record every decl and comment, in file order", sub {
    expect([map {[$_->{kind}, $_->{declkind}]} @$list])->to_be([
      [decl => 'yatt:widget'],
      [decl => 'yatt:entity'],
      [comment => 'yatt'],
      [decl => 'yatt:argmacro'],
      [decl => 'yatt:widget'],
    ]);
  };

  it "should hold exact source spans (substr invariant)", sub {
    foreach my $entry (@$list) {
      my $span = substr($tmpl->{string}
                        , $entry->{startpos}
                        , $entry->{endpos} - $entry->{startpos});
      if ($entry->{kind} eq 'comment') {
        expect($span)->to_match(qr/\A<!--#.*-->\r?\n\z/s);
        expect($entry->{nlines})->to_be(scalar($span =~ tr/\n//));
      } else {
        expect($span)->to_match(qr/\A<!\w+:\w+.*>[ \t]*\r?\n\z/s);
      }
    }
  };
};

describe "part_body_source", sub {
  it "should bound entity body by the next decl, with comments blanked out", sub {
    my $e1 = $tmpl->get_type_item(entity => 'e1');
    # コメント span (改行 3 個) が \n\n\n に置換され、行番号が保存される
    expect($tmpl->part_body_source($e1))
      ->to_be(qq{my \$v = "E1";\n\n\n\n\$v;\n});
  };

  it "should compile and render correctly", sub {
    expect($yatt->render('index'))->to_match(qr/^leading \[E1\]/);
  };
};

describe "back-to-back declarations (GH-275)", sub {
  my $yatt2 = YATT::Lite->new(
    app_ns => "TestBoundaryList2",
    vfs => [data => {index => "<!yatt:args>\n<!yatt:widget a>\n<!yatt:widget b>\nbody b\n"}],
  );
  my ($tmpl2) = $yatt2->get_vfs->find_file('index');
  $yatt2->find_product(perl => $tmpl2);

  it "should record a distinct lineno for each decl", sub {
    expect([map {$_->{lineno}} @{$tmpl2->{_boundarylist}}])->to_be([1, 2, 3]);
  };

  it "should give each part its own startln", sub {
    expect([map {[$_->{name}, $_->{startln}]} $tmpl2->list_parts])
      ->to_be([['', 1], ['a', 2], ['b', 3]]);
  };
};

done_testing();
