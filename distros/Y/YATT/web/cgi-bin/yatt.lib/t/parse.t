#!/usr/bin/perl -w
# -*- mode: perl; coding: utf-8 -*-
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Test::More qw(no_plan);

use FindBin;
use lib "$FindBin::Bin/..";

use YATT;
use YATT::Test;
use YATT::LRXML::Node qw(TEXT_TYPE);
require YATT::Test;

use Data::Dumper;

require_ok('YATT::LRXML::Parser');
YATT::break_parser;

my $example = 0;
{
  my $parser = new YATT::LRXML::Parser(namespace => [qw(yatt perl)]);

  is_deeply(scalar $parser->parse_entities('foo&perl:var.bar;baz', 0)
	    , [TEXT_TYPE, undef
	       ,'foo'
	       , $parser->create_node(entity => [qw(perl var bar)])
	       , 'baz']
	    , 'attvalue');

  is_deeply(scalar $parser->parse_entities('foo&perl(:var.bar);baz', 0)
	    , [TEXT_TYPE, undef
	       ,'foo'
	       , $parser->create_node(entity => undef, 'perl(:var.bar)')
	       , 'baz']
	    , 'call only');

  is_deeply(scalar $parser->parse_entities('foo&perl:var.bar{$baz+};baz', 0)
	    , [TEXT_TYPE, undef
	       , 'foo'
	       , $parser->create_node(entity => [qw(perl var)], '.bar{$baz+}')
	       , 'baz' ]
	    , 'attvalue: with dot/curly subscript');

  is_deeply(scalar $parser->parse_entities('q=&perl:_[1].param(q);<br/>', 0)
	    , [TEXT_TYPE, undef
	       , 'q='
	       , $parser->create_node(entity => [qw(perl)], ':_[1].param(q)')
	       , '<br/>']
	    , 'attvalue: with bracket/funcall subscript');

  is_deeply(scalar $parser->parse_entities('&perl:bar;', 0)
	    , $parser->create_node(entity => [qw(perl bar)])
	    , 'attvalue: entity only');

  is_deeply(scalar $parser->parse_entities('&perl:bar;baz', 0)
	    , [TEXT_TYPE, undef
	       , $parser->create_node(entity => [qw(perl bar)])
	       , 'baz',
	      ]
	    , 'attvalue: missing leading text');


  my $src = q(
<html>
<body>
<?perl my $user = $CGI.param("user"); ?>
<!--#perl comment -->
<h2>Welcom &perl:user;</h2>
</body>
</html>
);

  $parser = YATT::LRXML::Parser->new(namespace => [qw(yatt perl)]);
  {
    use Carp;
    local $SIG{__DIE__} = sub {
      confess(@_);
    };
    $parser->parse_string($src);
  }
  is $parser->tokens->[1]
    , '<?perl my $user = $CGI.param("user"); ?>'
    , "ex$example. Parser. pi";

  # XXX: readable でない (open していない、current が無い)状態なので、
  # node_type_name が delegate されない。
  # is $parser->tree->node_type_name
  #  , 'root', "ex$example. \$tree is root";

  is $parser->tree->stringify, $src, "ex$example.  round trip";

  # XXX: linenum の検査を.

  #----------------------------------------
  $example++;
  $src = <<'END';
<html>
<body>
<?perl &perl:varname; ?>
<!--#perl comment
 <perl:tag> ... </perl:tag>
-->
<!--foo bar-->
<h2>Welcom &perl:user;</h2>
</body>
</html>
END

  $parser->parse_string($src);
  my $tree = $parser->tree;
  print "tokens == \n", Dumper(scalar $parser->tokens), "\n" if $ENV{VERBOSE};
  print "tree == \n", Dumper($tree), "\n" if $ENV{VERBOSE};

  {
    my $scan = $parser->scanner(undef);
    my ($i, @lines, @list, @nols) = (0);
    while ($scan->readable) {
      push @lines, $scan->linenum;
      push @list, $scan->read;
      push @nols, $scan->last_nol;
      $i++;
    }
    is $i, 7, "ex$example. number of feedable feeds.";
    is_deeply \@list, ['<html>
<body>
','<?perl &perl:varname; ?>','
','<!--#perl comment
 <perl:tag> ... </perl:tag>
-->','
<!--foo bar-->
<h2>Welcom ','&perl:user;','</h2>
</body>
</html>
'], "ex$example. token structure";
    is_deeply \@lines, [qw(1 3 3 4 6 8 8)], "ex$example. token lines";
    is_deeply \@nols, [qw(2 0 1 2 2 0 3)], "ex$example. token nols";
  }
  is $tree->size, 7, "ex$example. size of parsed tree";

  is $tree->stringify, $src, "ex$example.  round trip";

  #----------------------------------------
  $example++;
  $src = <<'END';
<html>
<body>
<?perlZZ &perlZZ:varname; ?>
<!--#perlZZ comment
 <perlZZ:tag> ... </perlZZ:tag>
-->
<perlZZ:tag> ... </perlZZ:tag>
<!--foo bar-->
<h2>Welcom &perlZZ:user;</h2>
</body>
</html>
END

  $parser->parse_string($src);
  $tree = $parser->tree;
  print "tokens == \n", Dumper(scalar $parser->tokens), "\n" if $ENV{VERBOSE};
  print "tree == \n", Dumper($tree), "\n" if $ENV{VERBOSE};

  is $tree->size, 1, "ex$example. size of parsed tree";

  is $tree->stringify, $src, "ex$example.  round trip";

  #----------------------------------------
  is $parser->parse_string('<input type=radio checked>')->stringify
    , q(<input type=radio checked />), q(<input type=radio checked />);

  #----------------------------------------

  $example++;
  $src = <<'END';
header
<form>
<table>
<perl:foreach my=row list='1..8, &perl:param:FOO;'>
<tr>
<perl:foreach my=col list='1..8, &perl:param:BAR;'>
<td><input type=radio name='q&perl:var:row;' value="&perl:var:col;" /> &perl:var:col;</td>
</perl:foreach>
</tr>
  <:perl:join />と</perl:foreach>
</table>
</form>
footer
END

  $parser->parse_string($src);
  $tree = $parser->tree;
  print "tokens == \n", Dumper(scalar $parser->tokens), "\n" if $ENV{VERBOSE};
  print "tree == \n", Dumper($tree), "\n" if $ENV{VERBOSE};

  {
    my $scan = $parser->scanner(undef);
    my ($i, @lines, @list, @nols) = (0);
    while ($scan->readable) {
      push @lines, $scan->linenum;
      push @list, $scan->read;
      push @nols, $scan->last_nol;
      $i++;
    }
    is $i, 19, "ex$example. number of feedable feeds.";
    is_deeply \@list, ['header
', '<form>', '
<table>
', q|<perl:foreach my=row list='1..8, &perl:param:FOO;'>|, '
<tr>
', q|<perl:foreach my=col list='1..8, &perl:param:BAR;'>|, '
<td>', q|<input type=radio name='q&perl:var:row;' value="&perl:var:col;" />|,' ', '&perl:var:col;', '</td>
', '</perl:foreach>', '
</tr>
  ', '<:perl:join />', 'と', '</perl:foreach>', '
</table>
', '</form>', '
footer
'], "ex$example. token structure";
    is_deeply \@lines, [qw(1 2 2 4 4 6 6 7 7 7 7 8 8 10 10 10 10 12 12)]
      , "ex$example. token lines";
    is_deeply \@nols,  [qw(1 0 2 0 2 0 1 0 0 0 1 0 2  0  0  0  2  0  2)]
      , "ex$example. token nols";
  }
  is $tree->size, 3, "ex$example. size of parsed tree";

  eq_or_diff($tree->stringify, $src, "ex$example.  round trip");
  # タグの対応エラーを検出し、その行番号が一致していることを確認せよ。

  # foo='\'' を確認せよ

  #----------------------------------------

  $example++;
  $src = <<'END';
header
<form>
<perl:if var=q value=1>foo
<:perl:else var=q value=2 />bar
<:perl:else var=q value=3 />baz
<:perl:else />bang
</perl:if>
</form>
footer
END

  $parser->parse_string($src);
  $tree = $parser->tree;
  print "tokens == \n", Dumper(scalar $parser->tokens), "\n" if $ENV{VERBOSE};
  print "tree == \n", Dumper($tree), "\n" if $ENV{VERBOSE};

  is $tree->size, 3, "ex$example. size of parsed tree";

  is $tree->stringify, $src, "ex$example. round trip.";

  #----------------------------------------
  my $elem = $parser->parse_string('<form><input name=q value=v></form>');
  is($elem->open->node_type_name, 'html' , 'is html');

  is($elem->open->node_name, 'form', 'is <form>');
  is($elem->open->open->node_name, 'input', 'is <input>');
}

{
  $example++;
  my $parser = YATT::LRXML::Parser->new(namespace => [qw(yatt perl)]
				       , debug => $ENV{DEBUG} ? 1 : 0);
  # stringify は通常 \s+ を ' ' にするので、一致検査のための前処理が必要。
  my $tree = $parser->parse_string(map {s/\\\n\s*/ /g; $_} my $src = <<'END');
<!yatt:widget foo1 nameonly2 "valueonly3"\
  -- Here is comment ! --\
 name4=value name5='value' name6="value"\
 name7=type|default name8=type?default name9="type/default"\
  --
    more more comment
  --\
 %yatt:foo10(bar=baz,bang=hoe);\
 body11 = [code name11_1=text1 name11_2= value2 ]\
 title12=[  code name12_1=text name12_2=value2]>
body
<!yatt:test >
END

  is $tree->open->size, 14, "ex$example. size of decl of 'foo1'";
  is $tree->stringify, (map {
    # s/\n//g;
    s/\s+\]/\]/g;
    s/\[\s+/\[/g;
    s/\s*=\s*/=/g;
    # s/\s+--(.*?)--\s+/ --$1-- /gs;
    $_
  } $src)[0], "ex$example. round trip.";
}

my $src1 = <<'END';
<h2>&yatt:title;</h2>
<ul>
<yatt:foreach my=x list="@_">
<li>&yatt:x; <yatt:foobar y=8 x=3 /></li>
</yatt:foreach>
</ul>
<!yatt:widget foobar x=hoehoe y=bar>
<h2>&yatt:x;-&yatt:y;</h2>
<!yatt:widget baz z w>
<h2>&yatt:z;-&yatt:w;</h2>
END

{
  my $tree = read_string YATT::LRXML($src1, filename => $0);
  print Dumper($tree) if $ENV{DEBUG};

  is $tree->size, 17, 'LRXML is correctly parsed';

  eq_or_diff $tree->stringify, $src1, 'LRXML round trip';
}

{
  my $parser = new YATT::LRXML::Parser;
  my $html
    = q{<yatt:foo
&yatt:var;
my:foo
my:bar='BAR'><:yatt:baz>BAZ</:yatt:baz>bang</yatt:foo>};

  # XXX: Currently, \n in tag is not preserved.
  $html =~ s{\n}{ }g;

  my $elem = $parser->parse_string($html)->open;
  is_deeply [$elem->node_name, $elem->node_path], [qw(foo
						      yatt foo)]
    , 'name of elem';

  eq_or_diff $elem->stringify, $html, "round trip of my";

  my $att = $elem->open;
  is_deeply [scalar $att->node_name, do {
    my $body = $att->open;
    ($body->size, $body->node_type_name, [$body->node_path])
  }], [undef, 0, 'entity', ['yatt', 'var']]
    , 'unnamed bare att';

  $att->next;
  is_deeply [[$att->node_path], $att->node_body], [[qw(my foo)], undef]
    , 'bare nsname attname';

  $att->next;
  is_deeply [[$att->node_path], $att->node_body], [[qw(my bar)], 'BAR']
    , 'nsname attname = value';

  $att->next;
  is join("=", $att->node_name, $att->node_body)
    , "baz=BAZ", 'element attr';
}

if (0)
{
  print YATT::Translator::Perl->from_string($src1, filename => $0)
    ->translate_as_subs_to(qw(print index));

#  print YATT::Translator::JavaScript->new($tree)
#    ->translate_as_function('index');
}

{
  my $src3 = <<'END';
<h2>&yatt:file(=@$_);</h2>
END

  my $tree = read_string YATT::LRXML($src3, filename => $0);
  print Dumper($tree) if $ENV{DEBUG};

  is $tree->size, 3, 'LRXML is correctly parsed';

  eq_or_diff $tree->stringify, $src3, 'LRXML round trip';
}

{
  # missing close tag.
  my $parser = new YATT::LRXML::Parser;
  my $html = q{<yatt:foo>bar};

  YATT::Test::raises([$parser => parse_string => $html]
		     , qr{^Missing close tag 'foo'}, "missing close tag");
}
