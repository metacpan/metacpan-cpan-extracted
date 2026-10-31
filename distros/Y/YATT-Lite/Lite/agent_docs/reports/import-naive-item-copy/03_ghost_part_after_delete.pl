#!/usr/bin/env perl
#
# 検証 03: コピー元ファイルを削除しても、_Item コピーで取り込んだ part は
# 呼び出せ続ける(ゴースト part)。
#
# 補足: Template::refresh (Core.pm:690-692) はファイル消失時に
# 「return; # XXX: ファイルが消された」とキャッシュ温存で早期 return する
# ため、VFS レベルでは form 自体も当面キャッシュから描画され続ける。
# ただし URL レベルでは SiteApp の lookup_path が実ファイル存在を見るので
# /form へのアクセスは 404 になる。つまり「URL 面では消えたのに、
# コピー先の child 上では生き続ける」という非対称が問題になる。
# 対して lookup 時解決(base 相当)なら、ソース消失時の扱いを
# lookup_1/refresh の一箇所で将来一括修正できる。コピー方式では
# 全コピー先に古い強参照が散らばり、どんな修正も届かない。
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use File::Temp qw(tempdir);
END {chdir "/"}

use YATT::Lite::WebMVC0::SiteApp;
use YATT::Lite::Util::File qw(mkfile_may_wait);
use Plack::Test;
use HTTP::Request::Common;

my $TMP = tempdir(CLEANUP => 1);
my $docroot = "$TMP/app/docs";

YATT::Lite::Util::File->mkfile_may_wait(
  "$docroot/form.yatt" => <<'END'
<h2>form default</h2>
<!yatt:page confirm>
confirm (from form.yatt)
END
  ,
  "$docroot/child.yatt" => "<h2>child default</h2>\n",
);

my $site = YATT::Lite::WebMVC0::SiteApp->new(
  app_ns => 'TestImport03',
  app_root => "$TMP/app",
  doc_root => $docroot,
);
my $test = Plack::Test->create($site->to_app);
my $trans = $site->get_yatt('/')->open_trans;

my $tmplChild = $trans->find_file('child');
my $tmplForm  = $trans->find_file('form');

# --- 素朴 import の模倣(コピー) ---
$tmplChild->{_Item}{confirm} = $tmplForm->{_Item}{confirm};

sub naive_render_via_child {
  my $part = $tmplChild->{_Item}{confirm} or return "(no part)";
  my $pkg = $trans->find_product(perl => $part->cget('folder'));
  my $sub = $pkg->can("render_confirm") or return "(can() failed)";
  my $out = "";
  open my $fh, '>', \$out;
  $sub->($pkg, $fh);
  close $fh;
  $out;
}

print "== (1) 削除前 ==\n";
print "child のコピー経由: ", naive_render_via_child();
my $res = $test->request(GET "/form");
printf "GET /form          : [%d]\n", $res->code;

# --- コピー元を削除 ---
unlink "$docroot/form.yatt" or die "unlink failed: $!";
$trans->reset_refresh_mark;   # 新リクエスト相当

print "\n== (2) form.yatt 削除後 ==\n";
$res = $test->request(GET "/form");
printf "GET /form          : [%d] (URL 面では消えている)\n", $res->code;
$res = $test->request(GET "/form?~confirm=1");
printf "GET /form?~confirm : [%d]\n", $res->code;
print "child のコピー経由: ", naive_render_via_child();
print "→ URL としては存在しないファイルの part が、コピー先からは\n";
print "  プロセスが生きている限り呼び出せ続ける。\n";
