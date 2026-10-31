#!/usr/bin/env perl
#
# 検証 01: parse 時に他テンプレートの Part を _Item へコピーする素朴な
# <!yatt:import> 実装(を手作業で模倣)では、find_part_handler の
# $pkg->can($method) が失敗して dispatch できないことを確認する。
#
# 模倣方法: child.yatt には <!yatt:base> を書かず、Core API 経由で
#   $tmplChild->{_Item}{confirm} = $tmplForm->{_Item}{confirm}
# を直接実行する。これは「declare_import が parse 時に Part を
# コピーする」実装が作るのと同じデータ状態である。
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use File::Temp qw(tempdir);
END {chdir "/"}  # tempdir CLEANUP のため

use YATT::Lite::Factory;
use YATT::Lite::Util::File qw(mkfile_may_wait);

my $TMP = tempdir(CLEANUP => 1);
my $docroot = "$TMP/app/docs";

YATT::Lite::Util::File->mkfile_may_wait(
  "$docroot/form.yatt" => <<'END'
<h2>form default</h2>
<!yatt:page confirm>
confirm page (defined in form.yatt)
END
  ,
  "$docroot/child.yatt" => <<'END'
<h2>child default</h2>
END
  ,
  # (3) の対照実験用: こちらは正規の <!yatt:base> を使う
  "$docroot/child_base.yatt" => <<'END'
<!yatt:base file="form.yatt">
<h2>child_base default</h2>
END
);

my $F = YATT::Lite::Factory->new(
  app_ns => 'TestImport01',
  app_root => "$TMP/app",
  doc_root => $docroot,
);

my $trans = $F->get_yatt('/')->open_trans;

my $tmplChild = $trans->find_file('child') or die "no child";
my $tmplForm  = $trans->find_file('form')  or die "no form";

# --- 素朴 import の模倣: Part オブジェクトをそのまま _Item へコピー ---
$tmplChild->{_Item}{confirm} = $tmplForm->{_Item}{confirm};

# --- (1) 実際の dispatch 経路 find_part_handler で呼んでみる ---
print "== (1) find_part_handler([child, page => confirm]) ==\n";
my @r = eval { $trans->find_part_handler(["child", page => "confirm"]) };
if ($@) {
  print "DIED: $@";
} else {
  print "OK: sub=$r[1] pkg=$r[2]\n";
}

# --- (2) なぜ失敗するか: part は見つかるが、pkg の解決が要求側 ---
print "\n== (2) 内訳 ==\n";
my $part = $tmplChild->{_Item}{confirm};
printf "part found in child->{_Item}: name=%s folder=%s\n",
  $part->cget('name'), $part->cget('folder')->cget('path');
my $pkgChild = $trans->find_product(perl => $tmplChild);
printf "find_product(child) = %s\n", $pkgChild;
printf "  %s->can('render_confirm') = %s\n",
  $pkgChild, ($pkgChild->can('render_confirm') // 'undef (FAIL)');

my $pkgForm = $trans->find_product(perl => $tmplForm);
printf "find_product(form)  = %s\n", $pkgForm;
printf "  %s->can('render_confirm') = %s\n",
  $pkgForm, ($pkgForm->can('render_confirm') // 'undef');

# --- (3) 対照実験: <!yatt:base> なら同じ呼び出しが通る(@ISA 経由) ---
print "\n== (3) 対照: <!yatt:base file=\"form.yatt\"> 版 ==\n";
@r = eval { $trans->find_part_handler(["child_base", page => "confirm"]) };
if ($@) {
  print "DIED: $@";
} else {
  printf "OK: pkg=%s (sub は \@ISA 経由で解決される)\n", $r[2];
  no strict 'refs';
  printf "  child_base の \@ISA = (%s)\n", join(", ", @{"$r[2]::ISA"});
}
