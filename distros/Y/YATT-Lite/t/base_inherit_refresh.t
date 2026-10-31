#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#
# <!yatt:base> の継承まわりの refresh / コンパイル順序の検証。
#
# 背景と実測の詳細は Lite/agent_docs/reports/import-naive-item-copy.md と
# その検証スクリプト(同名ディレクトリ 00〜05)を参照。
#
# このテストは「あるべき挙動」を表明する。GH-255 修正前の実装では
# case 1 と case 4 が fail する:
#
#  case 1: 子テンプレートの @ISA は CGen::setup_inheritance_for
#    (CGen.pm:53, CGen/Perl.pm:43) すなわち子のコンパイル時にしか
#    張られないため、プロセス起動後いきなり継承 page を踏むと
#    lookup_base (VFS.pm:319) の mro 分岐が空振りして 500 になる。
#    しかも find_part_handler (Core.pm:481) は part 探索が
#    find_product より先なので、失敗リクエスト自体はコンパイルを
#    引き起こさず、他のリクエストが子を普通に描画するまで直らない。
#
#  case 4: 子のコンパイル時に gen_putargs が名前付き実引数を
#    位置引数へ静的変換する。親の widget の引数宣言順を編集すると、
#    親側は Template::refresh (Core.pm:729-732) で再コンパイルされるが、
#    子の product は無効化されないため、名前付きで書いたはずの
#    実引数がクロス配線される(プロセス再起動までパラメータ化けが続く)。
#
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::Kantan;
use File::Temp qw/tempdir/;

use Plack::Test;
use HTTP::Request::Common;

use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::WebMVC0::SiteApp;
use YATT::Lite::Util::File qw/mkfile_may_wait/;

my $tempdir = tempdir(CLEANUP => 1);
END {chdir "/"}
my $testno = 0;

my $make_app = sub {
  my (%files) = @_;
  my $app_root = "$tempdir/t" . ++$testno;
  my $docroot = "$app_root/docs";
  YATT::Lite::Util::File->mkfile_may_wait(
    map {("$docroot/$_" => $files{$_})} keys %files
  );
  my $site = YATT::Lite::WebMVC0::SiteApp->new(
    app_ns => "TestBaseRefresh$testno",
    app_root => $app_root,
    doc_root => $docroot,
  );
  ($docroot, Plack::Test->create($site->to_app));
};

my $rewrite = sub {
  my ($path, $content) = @_;
  # mtime 比較 (Template::refresh) の前進は mkfile_may_wait が保証する
  # (~1 秒眠ることがある)。utime で mtime を進めてはならない (mkfile_may_wait
  # の待ち条件を汚染し、次の書き換えが mtime 分だけ実時間で眠ってしまう)。
  YATT::Lite::Util::File->mkfile_may_wait($path => $content);
};

describe "case 1: inherited page as the very first request", sub {
  my ($docroot, $test) = $make_app->(
    'base.ytmpl' => <<'END'
<h2>base</h2>
<!yatt:page confirm>
confirm from base
END
    ,
    'child.yatt' => <<'END'
<!yatt:base file="base.ytmpl">
<h2>child</h2>
END
  );

  # プロセス起動後、child.yatt が一度もコンパイルされていない状態で
  # いきなり継承 page を sigil で呼ぶ。
  it "should serve base's page even when child is not yet compiled", sub {
    my $res = $test->request(GET "/child?~confirm=1");
    expect($res->code)->to_be(200);
    expect($res->content)->to_match(qr/confirm from base/);
  };

  it "should serve it after child is compiled too (regression)", sub {
    $test->request(GET "/child");
    my $res = $test->request(GET "/child?~confirm=1");
    expect($res->code)->to_be(200);
    expect($res->content)->to_match(qr/confirm from base/);
  };
};

describe "case 2: editing base widget body", sub {
  my ($docroot, $test) = $make_app->(
    'base.ytmpl' => <<'END'
<!yatt:widget bhead>
[bhead v1]
END
    ,
    'child.yatt' => <<'END'
<!yatt:base file="base.ytmpl">
child body <yatt:bhead/>
END
  );

  it "should render v1 before edit", sub {
    my $res = $test->request(GET "/child");
    expect($res->code)->to_be(200);
    expect($res->content)->to_match(qr/\[bhead v1\]/);
  };

  it "should reflect the edit on the next request", sub {
    $rewrite->("$docroot/base.ytmpl", <<'END');
<!yatt:widget bhead>
[bhead v2 EDITED]
END
    my $res = $test->request(GET "/child");
    expect($res->code)->to_be(200);
    expect($res->content)->to_match(qr/\[bhead v2 EDITED\]/);
  };
};

describe "case 3: editing arg order of inherited page (sigil dispatch)", sub {
  my ($docroot, $test) = $make_app->(
    'base.ytmpl' => <<'END'
<!yatt:page confirm x y>
x=[&yatt:x;] y=[&yatt:y;]
END
    ,
    'child.yatt' => <<'END'
<!yatt:base file="base.ytmpl">
<h2>child</h2>
END
  );
  $test->request(GET "/child"); # 子をコンパイルさせておく (case 1 とは別の論点なので)

  it "should map CGI params by name before edit", sub {
    my $res = $test->request(GET "/child?~confirm=1&x=XX&y=YY");
    expect($res->code)->to_be(200);
    expect($res->content)->to_match(qr/x=\[XX\] y=\[YY\]/);
  };

  it "should keep mapping CGI params by name after swapping arg decls", sub {
    $rewrite->("$docroot/base.ytmpl", <<'END');
<!yatt:page confirm y x>
x=[&yatt:x;] y=[&yatt:y;]
END
    my $res = $test->request(GET "/child?~confirm=1&x=XX&y=YY");
    expect($res->code)->to_be(200);
    expect($res->content)->to_match(qr/x=\[XX\] y=\[YY\]/);
  };
};

describe "case 4: editing arg order of base widget (compiled caller in child)", sub {
  my ($docroot, $test) = $make_app->(
    'base.ytmpl' => <<'END'
<!yatt:widget bhead x y>
x=[&yatt:x;] y=[&yatt:y;]
END
    ,
    # 呼び出し側は名前付きで渡している。
    # gen_putargs はこれを子のコンパイル時に位置引数へ静的変換する。
    'child.yatt' => <<'END'
<!yatt:base file="base.ytmpl">
child: <yatt:bhead x="XX" y="YY"/>
END
  );

  it "should map named args correctly before edit", sub {
    my $res = $test->request(GET "/child");
    expect($res->code)->to_be(200);
    expect($res->content)->to_match(qr/x=\[XX\] y=\[YY\]/);
  };

  it "should keep mapping named args after swapping arg decls in base", sub {
    $rewrite->("$docroot/base.ytmpl", <<'END');
<!yatt:widget bhead y x>
x=[&yatt:x;] y=[&yatt:y;]
END
    my $res = $test->request(GET "/child");
    expect($res->code)->to_be(200);
    # 親は refresh で再コンパイルされるが、子の呼び出し側 product が
    # 再生成されなければ x と y が入れ替わってしまう
    expect($res->content)->to_match(qr/x=\[XX\] y=\[YY\]/);
  };
};

done_testing();
