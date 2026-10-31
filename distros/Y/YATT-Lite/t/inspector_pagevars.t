#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#
# GH-286: LanguageServer (Inspector) support for pagevars (GH-282)
#
#  - definition of &yatt:NAME; jumps to the line in the pagevars module
#  - hover shows kind/type/value of the page constant
#  - completion lists page constants
#  - arguments shadow page constants; non-page templates (ytmpl) get none
#  - lint of a page in a subdirectory succeeds
#
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use File::Temp qw(tempdir);

use YATT::t::t_preload; # To make Devel::Cover happy.

use YATT::Lite::Util qw(untaint_any);
use YATT::Lite::Util::File qw(mkfile_may_wait);

BEGIN {
  foreach my $req (qw(Plack Plack::Response Hash::MultiValue
                      File::AddInc MOP4Import::Base::CLI_JSON Text::Glob
                      URI::file)) {
    unless (eval qq{require $req}) {
      plan skip_all => "$req is not installed."; exit;
    }
  }
}

use YATT::Lite::Inspector;

my $TMP = tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1);
END {
  chdir('/');
}

#========================================
# Fixture
#========================================
my $app = untaint_any("$TMP/app");

my $pm_text = <<'END';
package InspPV;
use strict;
use YATT::Lite::PageConsts -as_base, qw(as_html);

my @common = (site => "SITE");

MY->define_page(index => +{
  title => "Top page",
  items => [qw(a b)],
  @common,
});

MY->define_page('sub/q1' => +{
  title => "Q1",
  shadowed => "PV",
  note => as_html("<b>n</b>"),
  fmt => sub {"<$_[0]>"},
});

1;
END

my $index_text = <<'END';
<!yatt:args>
<h1>&yatt:title;</h1>&yatt:site;
<yatt:foreach my=i list=items>&yatt:i;</yatt:foreach>
<yatt:layout title="x"/>
END

my $q1_text = <<'END';
<!yatt:args shadowed>
&yatt:title; &yatt:shadowed; &yatt:note;
&yatt:fmt(1);
END

my $layout_text = <<'END';
<!yatt:args title>
&yatt:title;
END

MY->mkfile_may_wait
  ("$app/app.psgi", <<'END'
# -*- perl -*-
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use YATT::Lite::WebMVC0::SiteApp -as_base;
{
  my $SITE = MY->load_factory_for_psgi
    ($0
     , app_ns => 'TestInspPV1'
     , doc_root => "$FindBin::Bin/public"
     , app_base => '@ytmpl'
     , pagevars => 'InspPV'
    );
  if ($SITE->want_object) {
    return $SITE;
  } else {
    return $SITE->to_app;
  }
}
END
   , "$app/lib/InspPV.pm", $pm_text
   , "$app/public/index.yatt", $index_text
   , "$app/public/sub/q1.yatt", $q1_text
   , "$app/ytmpl/layout.ytmpl", $layout_text
  );

my $pm = "$app/lib/InspPV.pm";
my $index = "$app/public/index.yatt";
my $q1 = "$app/public/sub/q1.yatt";
my $layout = "$app/ytmpl/layout.ytmpl";

#========================================
# Helpers (see t/inspector_definition.t)
#========================================

sub pos_of {
  my ($text, $needle, $inner) = @_;
  my $off = index($text, $needle);
  die "no such text: $needle" if $off < 0;
  $off += $inner // 0;
  my $pre = substr($text, 0, $off);
  my $line = ($pre =~ tr/\n//);
  my $col = $off - (rindex($pre, "\n") + 1);
  ($line, $col);
}

sub line_of { (pos_of(@_))[0] }

sub uri_of { URI::file->new_abs($_[0])->as_string }

my $ins = YATT::Lite::Inspector->new(dir => $app);

sub definition_of {
  my ($file, $text, $needle, $inner) = @_;
  my ($sym, $cursor) = $ins->locate_symbol_at_file_position
    ($file, pos_of($text, $needle, $inner)) or return undef;
  $ins->lookup_symbol_definition($sym, $cursor);
}

sub hover_of {
  my ($file, $text, $needle, $inner) = @_;
  my ($sym, $cursor) = $ins->locate_symbol_at_file_position
    ($file, pos_of($text, $needle, $inner)) or return undef;
  my $md = $ins->describe_symbol($sym, $cursor) or return undef;
  $md->{value};
}

sub is_location {
  my ($got, $uri, $start_line, $title) = @_;
  subtest $title, sub {
    ok $got, "found" or return;
    is $got->{uri}, $uri, "uri";
    is $got->{range}{start}{line}, $start_line, "range.start.line";
    ok ref $got->{range}{end} eq 'HASH' && defined $got->{range}{end}{line}
      , "range.end is a Position (range is a Range, not a Position)";
  };
}

#========================================
# definition
#========================================

is_location(definition_of($index, $index_text, '&yatt:title;', 6)
            , uri_of($pm), line_of($pm_text, 'title => "Top page"')
            , "definition: pagevar in the top page");

is_location(definition_of($index, $index_text, '&yatt:site;', 6)
            , uri_of($pm), line_of($pm_text, 'my @common')
            , "definition: common value defined outside of the page block");

is_location(definition_of($q1, $q1_text, '&yatt:title;', 6)
            , uri_of($pm), line_of($pm_text, 'title => "Q1"')
            , "definition: pagevar in a page in a subdirectory");

is_location(definition_of($q1, $q1_text, '&yatt:shadowed;', 6)
            , uri_of($q1), line_of($q1_text, '<!yatt:args shadowed>')
            , "definition: argument shadows the pagevar of the same name");

is_location(definition_of($layout, $layout_text, '&yatt:title;', 6)
            , uri_of($layout), line_of($layout_text, '<!yatt:args title>')
            , "definition: templates outside of doc_root get no pagevars");

#========================================
# hover
#========================================

like(hover_of($index, $index_text, '&yatt:title;', 6) // ''
     , qr/pagevar title: text="Top page"/
     , "hover: text pagevar");

like(hover_of($q1, $q1_text, '&yatt:note;', 6) // ''
     , qr/pagevar note: html/
     , "hover: html pagevar");

like(hover_of($q1, $q1_text, '&yatt:fmt(1);', 6) // ''
     , qr/pagevar fmt: expr/
     , "hover: CODE pagevar is expr (GH-294)");

like(hover_of($q1, $q1_text, '&yatt:shadowed;', 6) // ''
     , qr/\(argument\) shadowed/
     , "hover: argument shadows the pagevar");

#========================================
# completion
#========================================

{
  my @items = $ins->complete_entities($index, "yatt", "", 1);
  my %by_label = map {$_->{label} => $_} grep {$_->{kind} == 13} @items;
  ok $by_label{title}, "completion: pagevar title in the top page";
  like $by_label{items}{detail} // '', qr/pagevar items: list/
    , "completion: detail of list pagevar";
}

{
  my @items = $ins->complete_entities($q1, "yatt", "sh", 1);
  my @shadowed = grep {$_->{kind} == 13 and $_->{label} eq 'shadowed'} @items;
  is scalar(@shadowed), 1
    , "completion: argument and pagevar of the same name are not duplicated";
}

#========================================
# lint
#========================================

{
  my $res = $ins->lint($q1);
  ok $res && $res->{is_success}
    , "lint: a page in a subdirectory using pagevars"
    or diag explain $res;
}

done_testing;
