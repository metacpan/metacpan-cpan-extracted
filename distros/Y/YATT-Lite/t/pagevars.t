#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test2::V0 -no_srand;
use File::Temp qw/tempdir/;

use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::WebMVC0::SiteApp;
use YATT::Lite::Util::File qw/mkfile_may_wait/;

my $tempdir = tempdir(CLEANUP => 1);
my $testno = 0;

{
  my $dir = "$tempdir/t" . ++$testno;

  #========================================

  {
    require lib;
    lib->import("$dir/lib");

    MY->mkfile_may_wait("$dir/lib/pagevars.pm", <<'END');
    #!/usr/bin/env perl
    package pagevars;
    use YATT::Lite::PageConsts -as_base, qw(as_html);

    my @common = (cmn => "CMN");

    my %PAGES;
    $PAGES{index} = +{
      foo => "FOO",
      bar => "BARRR",
      @common,
    };
    $PAGES{uselayout} = +{
      qux => "QUX",
    };
    $PAGES{'sub/another'} = +{
      baz => "BAZZZ",
      qux => as_html("foo<b>bar</b>baz"),
    };
    $PAGES{fncall} = +{
      fn => sub {join "+", @_},
      cond => sub {$_[0] > 1},
    };

    MY->define_pages_from_hash(\%PAGES);
    MY->cli_run(\@ARGV) unless caller;
    1;
END

      MY->mkfile_may_wait("$dir/public/index.yatt", <<'END');
&yatt:foo; &yatt:bar;
END

      MY->mkfile_may_wait("$dir/public/sub/another.yatt", <<'END');
&yatt:baz; &yatt:qux;
END

      # CODE constants are expr: their return value is printed with escape,
      # and usable as values in expressions (GH-294).
      MY->mkfile_may_wait("$dir/public/fncall.yatt", <<'END');
[&yatt:fn(1,<b>);]<yatt:if "&yatt:cond(2);">yes</yatt:if>
END

      MY->mkfile_may_wait("$dir/public/uselayout.yatt", <<'END');
&yatt:qux;<yatt:layout/>
END

      # Templates in ytmpl/ are not pages (page_name is undef),
      # so pagevars must not be applied to them.
      MY->mkfile_may_wait("$dir/ytmpl/layout.ytmpl", <<'END');
(dummy)
END

  }

  my $site = YATT::Lite::WebMVC0::SiteApp->new(
    app_ns => "Test$testno",
    app_root => $dir,
    doc_root => "$dir/public",
    app_base => '@ytmpl',
    pagevars => 'pagevars',
    debug_cgen => $ENV{DEBUG_CGEN},
  );


  is($site->render("index"), "FOO BARRR\n", q{pagevar index});

  is($site->render("sub/another"), "BAZZZ foo<b>bar</b>baz\n", q{pagevar sub/another});

  is(eval {$site->render("fncall")} // "ERROR: $@", "[1+&lt;b&gt;]yes\n"
     , "CODE pagevar is expr: called with args, value printed with escape");

  is(eval {$site->render("uselayout")} // "ERROR: $@", "QUX(dummy)\n\n"
     , "page using a widget from ytmpl (non-page template)");

  {
    my $site2 = YATT::Lite::WebMVC0::SiteApp->new(
      app_ns => "Test${testno}b",
      app_root => $dir,
      doc_root => "$dir/public",
      app_base => '@ytmpl',
      pagevars => 'pagevars',
    );

    # Inspector and Walker load directories without $basedir.
    # page_prefix must not depend on which path loaded the directory first.
    $site2->load_yatt("$dir/public/sub");

    is(eval {$site2->render("sub/another")} // "ERROR: $@"
       , "BAZZZ foo<b>bar</b>baz\n"
       , "pagevar sub/another, directory loaded without basedir");
  }

  #========================================
  # const_type: value -> yatt variable type

  is([map {pagevars->const_type($_)}
      "str", 3, [1], {a => 1}, sub {}, pagevars::as_html("<b>")]
     , [qw(text text list scalar expr html)]
     , "const_type");

  #========================================
  # locate_const: where a constant is defined (file, 1-based line)

  {
    my $pm = "$dir/lib/pagevars.pm";
    my $line_of = do {
      my @lines = do {open my $fh, '<', $pm or die "$pm: $!"; <$fh>};
      sub {
        my ($re) = @_;
        my ($i) = grep {$lines[$_] =~ $re} 0 .. $#lines;
        defined $i ? $i+1 : undef;
      };
    };

    is([pagevars->locate_const(index => 'bar')]
       , [$pm, $line_of->(qr/^\s*bar =>/)]
       , "locate_const: key in the page block");

    is([pagevars->locate_const('sub/another' => 'qux')]
       , [$pm, $line_of->(qr/^\s*qux => as_html/)]
       , "locate_const: same name in another page is not confused");

    is([pagevars->locate_const(uselayout => 'qux')]
       , [$pm, $line_of->(qr/^\s*qux => "QUX"/)]
       , "locate_const: same name, the other page");

    is([pagevars->locate_const(index => 'cmn')]
       , [$pm, $line_of->(qr/my \@common/)]
       , "locate_const: common value defined outside of the page block");

    is([pagevars->locate_const(index => 'nosuch')], []
       , "locate_const: no such constant");

    #========================================
    # The pagevars module used standalone, in a separate process
    # (without YATT::Lite modules preloaded by the test).

    my @perl = ($^X, map {"-I$_"} grep {not ref $_} @INC);
    my $run = sub {
      open my $fh, '-|', @perl, @_ or die "Can't run perl: $!";
      chomp(my @lines = <$fh>);
      \@lines;
    };

    is($run->('-e', 'use pagevars "index"; print "$foo $bar\n"')
       , ["FOO BARRR"]
       , "use pagevars 'index' from ordinary perl code");

    require JSON::PP;
    my $out = $run->($pm, find_consts => 'index');
    is(@$out ? JSON::PP::decode_json($out->[0]) : undef
       , {foo => "FOO", bar => "BARRR", cmn => "CMN"}
       , "cli: find_consts");

    is($run->($pm, locate_const => index => 'bar')
       , [$pm, $line_of->(qr/^\s*bar =>/)]
       , "cli: locate_const");
  }

  like(do {
    local $@;
    eval q{
      package pagevars_nohash;
      use YATT::Lite::PageConsts -as_base;
      MY->define_pages_from_hash(index => +{x => 1});
      1;
    };
    $@;
  }, qr/HASH ref/, "define_pages_from_hash: takes a HASH ref");
}

# (file, re) -> 1-based line of the first line matching re
sub line_of_file {
  my ($file, $re) = @_;
  my @lines = do {open my $fh, '<', $file or die "$file: $!"; <$fh>};
  my ($i) = grep {$lines[$_] =~ $re} 0 .. $#lines;
  defined $i ? $i+1 : undef;
}

#========================================
# define_page: each page records where it is defined
#========================================
{
  my $dir = "$tempdir/t" . ++$testno;
  lib->import("$dir/lib");

  MY->mkfile_may_wait("$dir/lib/pagevars2.pm", <<'END');
package pagevars2;
use YATT::Lite::PageConsts -as_base;

my @common = (cmn => "CMN");

MY->define_page(index => +{
  title => "Top",
  @common,
});

MY->define_page(q01 => +{
  title => "Q1",
});

# Keys are computed, so they can not be found in the source.
MY->define_page('q01/confirm' => +{
  map {("c$_" => $_)} 1 .. 2
});

1;
END

  MY->mkfile_may_wait("$dir/public/index.yatt", <<'END');
&yatt:title; &yatt:cmn;
END

  MY->mkfile_may_wait("$dir/public/q01/confirm.yatt", <<'END');
&yatt:c1;&yatt:c2;
END

  my $site = YATT::Lite::WebMVC0::SiteApp->new(
    app_ns => "Test$testno",
    app_root => $dir,
    doc_root => "$dir/public",
    pagevars => 'pagevars2',
  );

  is($site->render("index"), "Top CMN\n", "define_page: render");
  is($site->render("q01/confirm"), "12\n", "define_page: render, subdirectory");

  my $pm = "$dir/lib/pagevars2.pm";
  my $line = sub {line_of_file($pm, shift)};

  is([pagevars2->locate_page('index')]
     , [$pm, $line->(qr/define_page\(index/)]
     , "locate_page: line of define_page");

  is([pagevars2->locate_page('q01/confirm')]
     , [$pm, $line->(qr/define_page\('q01\/confirm'/)]
     , "locate_page: line of define_page, page in subdirectory");

  is([pagevars2->locate_const(index => 'title')]
     , [$pm, $line->(qr/title => "Top"/)]
     , "locate_const: key in the block of define_page");

  is([pagevars2->locate_const(q01 => 'title')]
     , [$pm, $line->(qr/title => "Q1"/)]
     , "locate_const: same name in another page is not confused");

  is([pagevars2->locate_const(index => 'cmn')]
     , [$pm, $line->(qr/my \@common/)]
     , "locate_const: common value");

  is([pagevars2->locate_const('q01/confirm' => 'c1')]
     , [$pm, $line->(qr/define_page\('q01\/confirm'/)]
     , "locate_const: key not found in the source -> line of define_page");

  #----------------------------------------
  # Redefinition of a page is an error.

  my $err = do {
    local $@;
    eval q{
#line 1 "dup.pm"
      package pagevars_dup;
      use YATT::Lite::PageConsts -as_base;
      MY->define_page(a => +{x => 1});
      MY->define_page(a => +{x => 2});
      1;
    };
    $@;
  };
  like($err
       , qr/Page .a. is already defined at \S*dup\.pm line 3, redefined at \S*dup\.pm line 4/
       , "define_page: redefinition croaks with both locations");

  #----------------------------------------
  # const_key_regexp can be overridden for local notations.

  MY->mkfile_may_wait("$dir/lib/pagevars3.pm", <<'END');
package pagevars3;
use YATT::Lite::PageConsts -as_base;

# This site writes constants as comma separated pairs.
sub const_key_regexp {
  my ($self, $name) = @_;
  qr/(['"])\Q$name\E\1\s*,/;
}

MY->define_page(index => +{
  'title', "Comma",
});

1;
END
  require pagevars3;

  is([pagevars3->locate_const(index => 'title')]
     , ["$dir/lib/pagevars3.pm"
        , line_of_file("$dir/lib/pagevars3.pm", qr/'title', "Comma"/)]
     , "const_key_regexp: overridden in the pagevars module");
}

done_testing;
