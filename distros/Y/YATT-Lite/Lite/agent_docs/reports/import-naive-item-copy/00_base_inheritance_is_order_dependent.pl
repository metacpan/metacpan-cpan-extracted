#!/usr/bin/env perl
#
# 検証 00(前提の実測): 現行の <!yatt:base> による page 継承 dispatch は
# 「子テンプレートがコンパイル済みか」に依存する。
#
# find_part_handler (Core.pm:522) には find_part_from フォールバックがあり、
# lookup_base (VFS.pm:319) が mro C3 で base を辿る設計になっているが、
# entns の @ISA は CGen の setup_inheritance_for (CGen.pm:53 →
# CGen/Perl.pm:43) すなわち「コード生成時」に張られる。
# find_part_handler では part 探索がコンパイル(find_product)より先なので、
# 未コンパイルの子への継承 page リクエストは part 探索に失敗し、
# その失敗自体はコンパイルを引き起こさないため、他のリクエストが
# 子をコンパイルするまで 500 が続く。
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use File::Temp qw(tempdir);
END {chdir "/"}

use YATT::Lite::WebMVC0::SiteApp;
use YATT::Lite::Util::File qw(mkfile_may_wait);
use YATT::Lite::Core; # Preload to set breakpoint.
use YATT::Lite::LRXML;
use Plack::Test;
use HTTP::Request::Common;

my $TMP = tempdir(CLEANUP => 1);
my $docroot = "$TMP/app/docs";

YATT::Lite::Util::File->mkfile_may_wait(
  "$docroot/form.yatt" => <<'END'
<h2>form</h2>
<!yatt:page confirm>
confirm from form
END
  ,
  "$docroot/child.yatt" => <<'END'
<!yatt:base file="form.yatt">
<h2>child</h2>
END
);

my $site = YATT::Lite::WebMVC0::SiteApp->new(
  app_ns => 'TestImport00',
  app_root => "$TMP/app",
  doc_root => $docroot,
);
my $test = Plack::Test->create($site->to_app);

# プロセス起動直後、いきなり継承 page → その後普通の page → もう一度継承 page
for my $path ("/child?~confirm=1", "/child", "/child?~confirm=1") {
  my $res = $test->request(GET $path);
  printf "%-22s : [%d] %s\n", $path, $res->code,
    substr($res->content, 0, 60) =~ s/\n/ /gr;
}
