#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#
# GH-275: Inspector go-to-definition (locate_symbol_at_file_position +
# lookup_symbol_definition) against a tempdir fixture.
#
#  - widget in the same file / another file / via <!yatt:base>
#  - widget argument, <yatt:my> variable: Location must be a real Range
#    (not a Position) with the uri of the declaring file
#  - entity function in <!yatt:entity> and in .htyattrc.pl (0-based line)
#  - cursor on plain text, past EOF, last line: undef, never croak
#  - the site path contains a space and non-ascii chars
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
                      File::AddInc MOP4Import::Base::CLI_JSON Text::Glob)) {
    unless (eval qq{require $req;}) {
      plan skip_all => "$req is not installed."; exit;
    }
  }
  unless (eval {require YATT::Lite::Inspector}) {
    plan skip_all => "YATT::Lite::Inspector is not loadable: $@"; exit;
  }
}

use URI::file;

my $TMP = tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1);
END {
  chdir('/');
}

#========================================
# Fixture (bare dir, no app.psgi). The path has a space and non-ascii
# octets so that uri <-> path conversion is exercised. GH-275
#========================================
my $site = untaint_any("$TMP/site with space/\xe3\x81\x82");

my $index_text = <<'END';
<!yatt:base file="base.ytmpl">
<!yatt:args x y="text?">
<h2>&yatt:x;</h2>
<yatt:foo a=y/>
<yatt:other:bar/>
<yatt:frombase/>
<yatt:my v="hello"/>
<yatt:my w:list="1,2"/>
&yatt:v; &yatt:w[0];
&yatt:ent();
&yatt:rcent();
plain text

<!yatt:widget foo a>
<h3>&yatt:a;</h3>

<!yatt:entity ent>
"ent";
END

my $other_text = <<'END';
<!yatt:widget bar z>
&yatt:z;
END

my $base_text = <<'END';
<!yatt:widget frombase>
FROM BASE
END

my $rc_text = <<'END';
use strict;
use YATT::Lite qw(Entity);

Entity rcent => sub {
  "rc";
};
END

MY->mkfile_may_wait
  ("$site/index.yatt", $index_text
   , "$site/other.yatt", $other_text
   , "$site/base.ytmpl", $base_text
   , "$site/.htyattrc.pl", $rc_text);

my $index = "$site/index.yatt";
my $other = "$site/other.yatt";
my $base = "$site/base.ytmpl";

#========================================
# Helpers
#========================================

# (0-based line, char) of the first occurrence of $needle in $text,
# shifted by $inner chars.
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

my $ins = YATT::Lite::Inspector->new(dir => $site);

sub definition_at {
  my ($file, $line, $col) = @_;
  my ($sym, $cursor) = $ins->locate_symbol_at_file_position($file, $line, $col)
    or return undef;
  my $loc = $ins->lookup_symbol_definition($sym, $cursor);
  $loc;
}

sub definition_of {
  my ($file, $text, $needle, $inner) = @_;
  definition_at($file, pos_of($text, $needle, $inner));
}

sub is_location {
  my ($got, $uri, $start_line, $start_char, $title) = @_;
  subtest $title, sub {
    ok $got, "found" or return;
    is $got->{uri}, $uri, "uri";
    is_deeply $got->{range}{start}
      , {line => $start_line, character => $start_char}, "range.start";
    ok ref $got->{range}{end} eq 'HASH' && defined $got->{range}{end}{line}
      , "range.end is a Position (range is a Range, not a Position)";
  };
}

#========================================
# Widgets
#========================================

is_location(definition_of($index, $index_text, '<yatt:foo', 6)
            , uri_of($index), line_of($index_text, '<!yatt:widget foo'), 0
            , "<yatt:foo> -> <!yatt:widget foo> in the same file");

is_location(definition_of($index, $index_text, '<yatt:other:bar', 12)
            , uri_of($other), 0, 0
            , "<yatt:other:bar> -> other.yatt");

is_location(definition_of($index, $index_text, '<yatt:frombase', 8)
            , uri_of($base), 0, 0
            , "<yatt:frombase> -> base.ytmpl via <!yatt:base>");

#========================================
# Arguments: Range must start at the argument token of the declaration
#========================================

is_location(definition_of($index, $index_text, '&yatt:x;', 6)
            , uri_of($index), pos_of($index_text, '<!yatt:args x', 12)
            , "&yatt:x; -> 'x' in <!yatt:args x ...>");

is_location(definition_of($index, $index_text, '&yatt:a;', 6)
            , uri_of($index), pos_of($index_text, '<!yatt:widget foo a', 18)
            , "&yatt:a; -> 'a' in <!yatt:widget foo a>");

is_location(definition_of($other, $other_text, '&yatt:z;', 6)
            , uri_of($other), pos_of($other_text, '<!yatt:widget bar z', 18)
            , "&yatt:z; -> 'z' in <!yatt:widget bar z> (first line)");

#========================================
# <yatt:my> variables
#========================================

is_location(definition_of($index, $index_text, '&yatt:v;', 6)
            , uri_of($index), pos_of($index_text, '<yatt:my v=', 9)
            , "&yatt:v; -> <yatt:my v=...>");

{
  my $loc = definition_of($index, $index_text, '&yatt:w[0];', 6);
  my ($line, $col) = pos_of($index_text, '<yatt:my w:list', 9);
  is_location($loc, uri_of($index), $line, $col
              , "&yatt:w[0]; -> <yatt:my w:list=...>");
  is_deeply $loc && $loc->{range}{end}
    , {line => $line, character => $col + length('w:list')}
    , "symbol_range covers 'w:list' (name:type path)";
}

#========================================
# Entity functions
#========================================

is_location(definition_of($index, $index_text, '&yatt:ent();', 6)
            , uri_of($index), line_of($index_text, '<!yatt:entity ent'), 0
            , "&yatt:ent() -> <!yatt:entity ent>");

{
  my $loc = definition_of($index, $index_text, '&yatt:rcent();', 6);
  ok $loc, "&yatt:rcent() found";
  like $loc->{uri}, qr{/\.htyattrc\.pl\z}, "-> .htyattrc.pl";
  # Sub::Identify reports the first statement of the sub (1-based).
  is $loc->{range}{start}{line}, line_of($rc_text, '"rc";')
    , "0-based line of the first statement of entity_rcent";
}

#========================================
# Never croak
#========================================

{
  my $nlines = () = $index_text =~ /\n/g;
  foreach my $case ([pos_of($index_text, 'plain text', 3), "plain text"]
                    , [$nlines - 1, 3, "last line, col > 0"]
                    , [$nlines, 5, "line == number of newlines, col > 0"]
                    , [99, 0, "line past EOF"]) {
    my ($line, $col, $title) = @$case;
    my $got = eval { definition_at($index, $line, $col) };
    is $@, '', "no exception: $title (line=$line col=$col)";
    is $got, undef, "undef: $title";
  }
}

#========================================
# GH-277: attributes at widget call sites
#   <yatt:foo x/>      name-only: variable x in scope (else formal arg x)
#   <yatt:foo a=y/>    name a: formal arg, value y: variable in scope
#   <yatt:foo b="..."> name b: formal arg (entities in the value as before)
#   <:yatt:d>          formal arg d
#========================================
my $call_text = <<'END';
<!yatt:args x y z d>

<yatt:foo x/>
<yatt:foo a=y/>
<yatt:foo b="&yatt:z;"/>
<yatt:foo verbose/>
<yatt:foo><:yatt:d>D</:yatt:d>BODY</yatt:foo>
<yatt:my v="hello"/>
<yatt:foo a=v/>

<!yatt:widget foo x a b d verbose=bool body=[code]>
<h2>&yatt:x;</h2>
END

my $call = "$site/call.yatt";
MY->mkfile_may_wait($call, $call_text);

is_location(definition_of($call, $call_text, '<yatt:foo x/>', 10)
            , uri_of($call), pos_of($call_text, '<!yatt:args x', 12)
            , "GH-277: name-only attribute x -> variable x in scope");

is_location(definition_of($call, $call_text, '<yatt:foo a=y/>', 10)
            , uri_of($call), pos_of($call_text, '<!yatt:widget foo x a', 20)
            , "GH-277: attribute name a -> formal arg a of foo");

is_location(definition_of($call, $call_text, '<yatt:foo a=y/>', 12)
            , uri_of($call), pos_of($call_text, '<!yatt:args x y', 14)
            , "GH-277: bare value y -> variable y in scope");

is_location(definition_of($call, $call_text, '<yatt:foo b="&yatt:z;"/>', 10)
            , uri_of($call), pos_of($call_text, '<!yatt:widget foo x a b', 22)
            , "GH-277: attribute name b -> formal arg b of foo");

is_location(definition_of($call, $call_text, '<yatt:foo b="&yatt:z;"/>', 19)
            , uri_of($call), pos_of($call_text, '<!yatt:args x y z', 16)
            , "entity in attribute value -> variable z (unchanged)");

is_location(definition_of($call, $call_text, '<yatt:foo verbose/>', 10)
            , uri_of($call), pos_of($call_text, 'verbose=bool')
            , "GH-277: name-only flag (no such variable) -> formal arg verbose");

is_location(definition_of($call, $call_text, '<:yatt:d>', 7)
            , uri_of($call), pos_of($call_text, '<!yatt:widget foo x a b d', 24)
            , "GH-277: attribute element <:yatt:d> -> formal arg d");

is_location(definition_of($call, $call_text, '<yatt:foo a=v/>', 12)
            , uri_of($call), pos_of($call_text, '<yatt:my v=', 9)
            , "GH-277: bare value v -> <yatt:my v=...>");

is definition_of($call, $call_text, '<yatt:my v=', 9), undef
  , "GH-277: attribute of a macro element (<yatt:my v=...>) has no definition";

# hover
{
  my $hover_of = sub {
    my ($needle, $inner) = @_;
    my ($sym, $cursor) = $ins->locate_symbol_at_file_position
      ($call, pos_of($call_text, $needle, $inner)) or return undef;
    my $md = $ins->describe_symbol($sym, $cursor) or return undef;
    $md->{value};
  };
  like $hover_of->('<yatt:foo x/>', 10), qr/\(argument\) x: text/
    , "GH-277: hover on name-only x describes the variable";
  like $hover_of->('<yatt:foo verbose/>', 10), qr/argument verbose of <yatt:foo>: bool/
    , "GH-277: hover on a flag attribute describes the formal arg";
  like $hover_of->('<yatt:foo a=y/>', 10), qr/argument a of <yatt:foo>: text/
    , "GH-277: hover on attribute name describes the formal arg";
  like $hover_of->('<yatt:foo a=y/>', 12), qr/\(argument\) y: text/
    , "GH-277: hover on bare value describes the variable";
}


#========================================
# GH-278: a multi-line <!--#yatt --> comment right before an element.
# The comment token includes its trailing newline, and its tree_range
# used to spill into the next line: the entity call on that line was
# taken as part of the comment (kind COMMENT), so no definition / hover.
#========================================
my $comment_text = <<'END';
<!yatt:args>
<html>
<body>
<!--#yatt xxx
                   yyy        #-->
<yatt:if "&yatt:foobar();">
  foobar=&yatt:foobar();
</yatt:if>
<yatt:body/>
</body>
</html>

<!yatt:entity foobar>
1;
END

my $comment = "$site/comment.yatt";
MY->mkfile_may_wait($comment, $comment_text);

{
  my ($sym) = $ins->locate_symbol_at_file_position
    ($comment, pos_of($comment_text, '<yatt:if "&yatt:foobar();">', 17));
  is $sym && $sym->{kind}, 'call'
    , "GH-278: symbol right after a multi-line comment is the entity call, not the comment";
}

is_location(definition_of($comment, $comment_text, '<yatt:if "&yatt:foobar();">', 17)
            , uri_of($comment), line_of($comment_text, '<!yatt:entity foobar>'), 0
            , "GH-278: entity call right after a multi-line comment -> <!yatt:entity foobar>");

is_location(definition_of($comment, $comment_text, '  foobar=&yatt:foobar();', 16)
            , uri_of($comment), line_of($comment_text, '<!yatt:entity foobar>'), 0
            , "entity call in the element body -> <!yatt:entity foobar> (unchanged)");

{
  my ($sym) = $ins->locate_symbol_at_file_position
    ($comment, pos_of($comment_text, 'yyy        #-->', 1));
  is $sym && $sym->{kind}, 'COMMENT'
    , "GH-278: inside the comment is still the comment";
  is definition_of($comment, $comment_text, 'yyy        #-->', 1), undef
    , "GH-278: no definition inside the comment";

  my ($sym2, $cursor2) = $ins->locate_symbol_at_file_position
    ($comment, pos_of($comment_text, '<yatt:if "&yatt:foobar();">', 17));
  my $md = $sym2 && $ins->describe_symbol($sym2, $cursor2);
  like $md && $md->{value}, qr/foobar/
    , "GH-278: hover right after a multi-line comment describes the entity";
}


#========================================
# GH-280: callable-variable elements and macro elements.
#   <yatt:body/>   implicit body arg -> the declaration line of the
#                  enclosing widget; explicit body=[code] -> its name token
#   <yatt:cb/>     cb=[code] arg -> its name token (even when a widget of
#                  the same name exists: gen_call looks up variables first)
#   <yatt:f/>      <yatt:my f:code=...> -> the variable
#   <yatt:if ...>  macro: hover only, no definition
#========================================
my $body_text = <<'END';
<!yatt:args x cb=[code] foo=[code]>
<yatt:wrap><yatt:body/>X</yatt:wrap>
<yatt:cb/>
<yatt:foo/>
<yatt:my f:code="&yatt:x;"/>
<yatt:f/>
<yatt:if "&yatt:x;">Y</yatt:if>

<!yatt:widget wrap>
<div><yatt:body/></div>

<!yatt:widget wrap2 body=[code]>
<yatt:body/>

<!yatt:widget foo>
FOO
END

my $body = "$site/callable.yatt";
MY->mkfile_may_wait($body, $body_text);

sub hover_of {
  my ($file, $text, $needle, $inner) = @_;
  my ($sym, $cursor) = $ins->locate_symbol_at_file_position
    ($file, pos_of($text, $needle, $inner)) or return undef;
  my $md = $ins->describe_symbol($sym, $cursor) or return undef;
  $md->{value};
}

is_location(definition_of($body, $body_text, '<div><yatt:body/>', 6)
            , uri_of($body), line_of($body_text, '<!yatt:widget wrap>'), 0
            , "GH-280: implicit body -> declaration line of the enclosing widget");

is_location(definition_of($body, $body_text, '<div><yatt:body/>', 14)
            , uri_of($body), line_of($body_text, '<!yatt:widget wrap>'), 0
            , "GH-280: implicit body, cursor on the last char of the name");

is_location(definition_of($body, $body_text, '<yatt:wrap><yatt:body/>', 12)
            , uri_of($body), 0, 0
            , "GH-280: implicit body of the page (nested in a call) -> <!yatt:args> line");

is_location(definition_of($body, $body_text, "body=[code]>\n<yatt:body/>", 14)
            , uri_of($body), pos_of($body_text, 'body=[code]')
            , "GH-280: explicit body=[code] -> the name token of the declaration");

is_location(definition_of($body, $body_text, '<yatt:cb/>', 6)
            , uri_of($body), pos_of($body_text, 'cb=[code]')
            , "GH-280: <yatt:cb/> -> cb=[code] arg");

is_location(definition_of($body, $body_text, '<yatt:foo/>', 6)
            , uri_of($body), pos_of($body_text, 'foo=[code]')
            , "GH-280: <yatt:foo/> -> foo=[code] arg, not the widget foo");

is_location(definition_of($body, $body_text, '<yatt:f/>', 6)
            , uri_of($body), pos_of($body_text, '<yatt:my f:code', 9)
            , "GH-280: <yatt:f/> -> <yatt:my f:code=...>");

is definition_of($body, $body_text, '<yatt:if "', 6), undef
  , "GH-280: macro element has no definition";

is_location(definition_of($body, $body_text, '<yatt:wrap><yatt:body/>', 6)
            , uri_of($body), line_of($body_text, '<!yatt:widget wrap>'), 0
            , "widget call -> widget declaration (unchanged)");

like hover_of($body, $body_text, '<div><yatt:body/>', 6), qr/\(argument\) body: code/
  , "GH-280: hover on <yatt:body/> describes the body argument";
like hover_of($body, $body_text, '<yatt:cb/>', 6), qr/\(argument\) cb: code/
  , "GH-280: hover on <yatt:cb/> describes the code argument";
like hover_of($body, $body_text, '<yatt:f/>', 6), qr/my f: code/
  , "GH-280: hover on <yatt:f/> describes the my variable";
like hover_of($body, $body_text, '<yatt:if "', 6), qr/\(macro\) <yatt:if>/
  , "GH-280: hover on a macro element";
like hover_of($body, $body_text, '<yatt:wrap><yatt:body/>', 6), qr/\(widget\) <yatt:wrap/
  , "hover on a widget call (unchanged)";

{
  # The undef placeholder locate_node inserts must not be autovivified
  # into a kind-less node by augment_defs (foreach aliasing). GH-280
  my ($sym, $cursor) = eval {
    $ins->locate_symbol_at_file_position
      ($body, pos_of($body_text, '<yatt:my f:code', 8));
  };
  is $@, '', "GH-280: whitespace inside <yatt:my .../> does not die";
  is $sym, undef, "GH-280: whitespace inside <yatt:my .../> is not a symbol";
}


done_testing();
