#!/usr/bin/env perl
#
# 検証 05: コピーの変種として「_Item だけでなく _partlist にも入れて、
# 取込側パッケージで再コンパイルさせる」実装を模倣する。
# (検証 01 の can() 問題は消えるが、別の問題が出る)
#
#  - part の中身が取込側の文脈で再解釈される(文脈シフト)。
#    form.yatt の confirm が呼ぶ <yatt:header/> が、form の header では
#    なく child の header に化ける。これは <!yatt:base> の継承意味論
#    としては「正しい」が、import(定義側静的束縛)の意味論としては
#    誤りであり、しかも yatt-js の静的束縛と非互換になる。
#  - 同じ part が form 側でも child 側でも二重にコンパイルされる。
#    エラー時の行番号・ファイル帰属も取込側にずれる。
#  - cgen は part->{folder} が「今コンパイル中のテンプレート」である
#    ことを暗黙に仮定している(エラー報告・ソース参照系)。コピーは
#    この不変条件を壊すため、将来の cgen 変更で静かに壊れる地雷になる。
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use File::Temp qw(tempdir);
END {chdir "/"}

use YATT::Lite::Factory;
use YATT::Lite::Util::File qw(mkfile_may_wait);

my $TMP = tempdir(CLEANUP => 1);
my $docroot = "$TMP/app/docs";

YATT::Lite::Util::File->mkfile_may_wait(
  "$docroot/form.yatt" => <<'END'
<h2>form default</h2>
<!yatt:widget confirm>
confirm says: <yatt:header/>
<!yatt:widget header>
[B-header (form.yatt)]
END
  ,
  "$docroot/child.yatt" => <<'END'
<h2>child default</h2>
<!yatt:widget header>
[A-header (child.yatt)]
END
);

my $F = YATT::Lite::Factory->new(
  app_ns => 'TestImport05',
  app_root => "$TMP/app",
  doc_root => $docroot,
);
my $trans = $F->get_yatt('/')->open_trans;

my $tmplChild = $trans->find_file('child');
my $tmplForm  = $trans->find_file('form');

# --- 変種: _Item と _partlist の両方へコピー(child は未コンパイルの内に) ---
my $part = $tmplForm->{_Item}{confirm};
$tmplChild->{_Item}{confirm} = $part;
push @{$tmplChild->{_partlist}}, $part;

print "== (1) child のパッケージでコンパイルできてしまうか ==\n";
my $pkgChild = eval { $trans->find_product(perl => $tmplChild) };
if ($@) {
  print "コンパイル自体が失敗: $@";
  exit;
}
my $sub = $pkgChild->can('render_confirm');
printf "%s->can('render_confirm') = %s\n", $pkgChild, ($sub // 'undef');

if ($sub) {
  print "\n== (2) child 版 confirm の出力(文脈シフト) ==\n";
  my $out = "";
  open my $fh, '>', \$out;
  eval { $sub->($pkgChild, $fh) };
  close $fh;
  print $@ ? "実行時エラー: $@" : $out;

  print "\n== (3) 対照: form 側の confirm 本来の出力 ==\n";
  my $pkgForm = $trans->find_product(perl => $tmplForm);
  $out = "";
  open $fh, '>', \$out;
  $pkgForm->can('render_confirm')->($pkgForm, $fh);
  close $fh;
  print $out;

  print "\n→ 同一 Part が2つのパッケージで別コードにコンパイルされ、\n";
  print "  <yatt:header/> の解決先が取込側の header にすり替わる。\n";
}
