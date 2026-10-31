#!/usr/bin/env perl
#
# 検証 04: 循環参照の扱い。
#
# (A) 現行の <!yatt:base> の相互参照(a.yatt ⇔ b.yatt)が現状どう
#     振る舞うかの実測。declare_base は parse 時に Part をコピーせず、
#     VFS 記述子(weaken 参照, VFS.pm:697-703)を置くだけなので、
#     少なくとも parse は循環しない。
#
# (B) 「parse 時に import 先を eager に読みに行って Part をコピーする」
#     実装の制御フローを模したシミュレーション。
#     parse(A) の完了が parse(B) の完了に依存し、その逆も然り、なので
#     コピーすべき確定した Part 集合が存在せず、再帰が止まらない。
#     (lookup 時解決なら「名前 → ソース」の表を置くだけで parse が
#      完了するため、この相互依存自体が発生しない)
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
  "$docroot/a.yatt" => <<'END'
<!yatt:base file="b.yatt">
page a body
<!yatt:widget wa>
widget wa (in a)
END
  ,
  "$docroot/b.yatt" => <<'END'
<!yatt:base file="a.yatt">
page b body
<!yatt:widget wb>
widget wb (in b)
END
);

my $site = YATT::Lite::WebMVC0::SiteApp->new(
  app_ns => 'TestImport04',
  app_root => "$TMP/app",
  doc_root => $docroot,
);
my $test = Plack::Test->create($site->to_app);

print "== (A) 相互 <!yatt:base> の現状の振る舞い(実測) ==\n";
local $SIG{ALRM} = sub { die "TIMEOUT (infinite loop?)\n" };
for my $path ("/a", "/b") {
  alarm 10;
  my $res = eval { $test->request(GET $path) };
  alarm 0;
  if ($@) {
    printf "%-4s : DIED: %s", $path, $@;
  } else {
    printf "%-4s : [%d] %s\n", $path, $res->code,
      substr($res->content, 0, 100) =~ s/\n/ /gr;
  }
}

print "\n== (B) eager コピー方式の parse 制御フローのシミュレーション ==\n";
my %SPEC = (
  'a.yatt' => { imports_from => 'b.yatt' },
  'b.yatt' => { imports_from => 'a.yatt' },
);
my %parsed;
my $depth = 0;
sub eager_parse {
  my ($file) = @_;
  die "  ... 再帰打ち切り (depth=$depth): parse が終わらない\n" if ++$depth > 6;
  printf "%sparse(%s) 開始\n", "  " x $depth, $file;
  # <!yatt:import> 行に到達 → コピーすべき Part を確定させるには
  # ソースの parse 完了が必要
  my $src = $SPEC{$file}{imports_from};
  printf "%s -> import 元 %s の Part が必要 → parse(%s)\n",
    "  " x $depth, $src, $src;
  eager_parse($src);
  $parsed{$file} = 1;  # ここには到達しない
}
eval { eager_parse('a.yatt') };
print $@ if $@;
print "(実際の実装では「parse 中フラグ」で検出してエラーにするか、\n";
print " lookup 時解決にして相互依存自体を解消するかの二択になる)\n";
