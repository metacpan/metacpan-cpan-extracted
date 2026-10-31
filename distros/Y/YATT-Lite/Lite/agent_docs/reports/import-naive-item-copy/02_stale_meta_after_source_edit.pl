#!/usr/bin/env perl
#
# 検証 02: _Item コピー方式は、コピー元ファイルの編集後に
# 「古い Part メタ情報 + 新しいコンパイル済みコード」の食い違いを起こし、
# CGI 引数が黙って別の引数へマップされる(クロス配線)。
#
# 前提: 検証 01 で見た通り、素朴コピーは $pkg->can で止まる。ここでは
# 「pkg を part->folder から引くよう改良した素朴実装」を模倣する
# (find_part_renderer :464-476 と同じ手順を手で行う)。
# それでも Part メタ(_arg_order)の陳腐化は防げないことを示す。
#
# ポイント:
#  - lookup_1 (VFS.pm:287) は「探しに行った先のファイル」しか refresh
#    しないため、child 側の _Item ヒットでは form.yatt の refresh が
#    一切走らない。
#  - 誰かが form を直接触ると form は refresh + 再コンパイルされるが、
#    child が握る Part オブジェクトは古いまま残る。
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use File::Temp qw(tempdir);
END {chdir "/"}

use YATT::Lite::Factory;
use YATT::Lite::Util::File qw(mkfile_may_wait);
use Scalar::Util qw(refaddr);

my $TMP = tempdir(CLEANUP => 1);
my $docroot = "$TMP/app/docs";

my $FORM_V1 = <<'END';
<h2>form default</h2>
<!yatt:page confirm x y>
x=[&yatt:x;] y=[&yatt:y;]
END

my $FORM_V2 = <<'END';
<h2>form default v2</h2>
<!yatt:page confirm y x>
x=[&yatt:x;] y=[&yatt:y;]
END

YATT::Lite::Util::File->mkfile_may_wait(
  "$docroot/form.yatt" => $FORM_V1,
  "$docroot/child.yatt" => "<h2>child default</h2>\n",
);

my $F = YATT::Lite::Factory->new(
  app_ns => 'TestImport02',
  app_root => "$TMP/app",
  doc_root => $docroot,
);
my $yatt = $F->get_yatt('/');
my $trans = $yatt->open_trans;

my $tmplChild = $trans->find_file('child');
my $tmplForm  = $trans->find_file('form');

# --- 素朴 import の模倣(コピー) ---
$tmplChild->{_Item}{confirm} = $tmplForm->{_Item}{confirm};

# 「改良版」素朴 dispatch: part->folder から product package を引く
sub naive_dispatch_via_child {
  my (%params) = @_;
  my $part = $tmplChild->{_Item}{confirm};       # child の _Item ヒット
  my @args = $part->reorder_hash_params(\%params); # ★古い _arg_order を使う
  my $pkg = $trans->find_product(perl => $part->cget('folder'));
  my $sub = $pkg->can("render_confirm") or die "can() failed";
  my $out = "";
  open my $fh, '>', \$out;
  $sub->($pkg, $fh, @args);
  close $fh;
  ($out, $part);
}

print "== (1) v1 の時点: child 経由の呼び出しは正常 ==\n";
my ($out) = naive_dispatch_via_child(x => 'XX', y => 'YY');
print $out;

# --- form.yatt を編集: 宣言の引数順を x y → y x に入れ替え ---
YATT::Lite::Util::File->mkfile_may_wait("$docroot/form.yatt" => $FORM_V2);
utime(time + 5, time + 5, "$docroot/form.yatt");  # mtime 前進を保証

# --- 新しいリクエストを模倣 ---
$trans->reset_refresh_mark;

print "\n== (2) 編集後、form を直接呼ぶと正しく更新される(refresh + 再コンパイル) ==\n";
print $yatt->render(['form', page => 'confirm'], {x => 'XX', y => 'YY'});

print "\n== (3) 同じ引数で child のコピー経由: 引数がクロス配線される ==\n";
(my $out3, my $stalePart) = naive_dispatch_via_child(x => 'XX', y => 'YY');
print $out3;

print "\n== (4) 内訳: Part の同一性と _arg_order ==\n";
my $freshPart = $tmplForm->{_Item}{confirm};
printf "child が握る Part : refaddr=%s arg_order=(%s)\n",
  refaddr($stalePart), join(",", map {$_ ? @$_ : ()} $stalePart->{_arg_order});
printf "form の現在の Part: refaddr=%s arg_order=(%s)\n",
  refaddr($freshPart), join(",", map {$_ ? @$_ : ()} $freshPart->{_arg_order});
print "→ 古い Part の _arg_order (x,y) で並べた実引数を、\n";
print "  再コンパイル済みの新しい sub (仮引数順 y,x) が受け取るため、\n";
print "  x と y の値が入れ替わって描画される。\n";

print "\n== (5) 対照: <!yatt:base> の lookup 経由なら編集が正しく反映される ==\n";
# (検証00の通り、base 継承 lookup は子のコンパイル後にのみ機能する。
#  ここでは render で child_base をコンパイルしてから示す)
YATT::Lite::Util::File->mkfile_may_wait(
  "$docroot/child_base.yatt" => qq{<!yatt:base file="form.yatt">\n<h2>cb</h2>\n});
my $F2 = YATT::Lite::Factory->new(
  app_ns => 'TestImport02b',
  app_root => "$TMP/app",
  doc_root => $docroot,
);
my $yatt2 = $F2->get_yatt('/');
$yatt2->render('child_base');  # 子をコンパイル(@ISA 確立)
print $yatt2->render(['child_base', page => 'confirm'], {x => 'XX', y => 'YY'});
