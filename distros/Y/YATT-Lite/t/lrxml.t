#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use YATT::Lite::Test::TestUtil;

use YATT::Lite::Util qw(catch);
use YATT::Lite::Constants;

use YATT::Lite::LRXML::ParseBody;

use Test::Differences;
use YATT::Lite::XHF::Dumper;


BEGIN {
  foreach my $req (qw(File::AddInc MOP4Import::Base::CLI_JSON)) {
    unless (eval qq{require $req}) {
      plan skip_all => "$req is not installed."; exit;
    }
  }
}

use YATT::Lite::LRXML::AltTree;
sub alt_tree_for {
  my ($string, $tree) = @_;
  [YATT::Lite::LRXML::AltTree->new(
    string => $string,
    with_text => 1,
    with_range => 0,
  )->convert_tree($tree)];
}
sub alt_tree_xhf_for {
  YATT::Lite::XHF::Dumper->dump_strict_xhf(alt_tree_for(@_))."\n";
}


my $CLASS = 'YATT::Lite::LRXML';
use_ok($CLASS);

# XXX: Node の内部表現は、本当はまだ固まってない。大幅変更の余地が有る
# ただ、それでも parse 結果もテストしておかないと、余計な心配が増えるので。

{
  my $parser = $CLASS->new(all => 1);
  my $tmpl = $CLASS->Template->new;
  $parser->load_string_into($tmpl, my $cp = <<END);
<!yatt:widget bar x y>
FOO
<yatt:foo x y>
bar
</yatt:foo>
BAZ

<!yatt:widget foo x y>
<h2>&yatt:x;</h2>
&yatt:y;
END


  {
    my $name = 'bar';
    is ref (my $w = $tmpl->{Item}{$name}), 'YATT::Lite::Core::Widget'
      , "tmpl Item '$name'";
    eq_or_diff $tmpl->source_region
      ($w->{cf_startpos}, $w->{cf_bodypos})
	, qq{<!yatt:widget bar x y>\n}, "part $name source_range decl";

    eq_or_diff $tmpl->source_substr($w->{cf_bodypos}, $w->{cf_bodylen})
      , q{FOO
<yatt:foo x y>
bar
</yatt:foo>
BAZ

}, "part $name source_range body";

    my $i = -1;
    is $w->{tree}[++$i], "FOO\n", "render_$name node $i";
    is_deeply $tmpl->node_source($w->{tree}[++$i])
      , q{<yatt:foo x y>
bar
</yatt:foo>}, "render_$name node $i";
    is $w->{tree}[++$i], "\nBAZ", "render_$name node $i"; # XXX \n が嬉しくない

    # print STDERR alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), "\n"; exit;
    
    eq_or_diff alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), <<'END';
[
-
 FOO
 
{
kind: ELEMENT
path[
yatt: foo
]
source: <yatt:foo x y>
 bar
 </yatt:foo>
subtree[
{
kind: ATTRIBUTE
path: x
source: x
value= #null
}
{
kind: ATTRIBUTE
path: y
source: y
value= #null
}
-
 
 
- bar
-
 
 
]
}
-
 
 BAZ
-
 
 
]
END

  }

  {
    my $name = 'foo';
    is ref (my $w = $tmpl->{Item}{$name}), 'YATT::Lite::Core::Widget'
      , "tmpl Item '$name'";
    eq_or_diff $tmpl->source_region
      ($w->{cf_startpos}, $w->{cf_bodypos})
	, qq{<!yatt:widget foo x y>\n}, "part $name source_range decl";

    eq_or_diff $tmpl->source_substr($w->{cf_bodypos}, $w->{cf_bodylen})
      , q{<h2>&yatt:x;</h2>
&yatt:y;
}, "part $name source_range body";

    my $i = -1;
    is $w->{tree}[++$i], "<h2>", "render_$name node $i";
    is_deeply $tmpl->node_source($w->{tree}[++$i])
      , '&yatt:x;', "render_$name node $i";
    is $w->{tree}[++$i], "</h2>\n", "render_$name node $i";
    is_deeply $tmpl->node_source($w->{tree}[++$i])
      , '&yatt:y;', "render_$name node $i";

    # print STDERR alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), "\n";

    eq_or_diff alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), <<'END';
[
- <h2>
{
kind: entpath
source: &yatt:x;
subtree[
{
kind: var
path: x
source: :x
}
]
}
-
 </h2>
 
{
kind: entpath
source: &yatt:y;
subtree[
{
kind: var
path: y
source: :y
}
]
}
-
 
 
]
END

  }
}

{
  my $tmpl = $CLASS->Template->new;
  $CLASS->load_string_into($tmpl, my $cp = <<END, all => 1);
<!yatt:args x=list y="scalar?0">
FOO
<!--#yatt 1 -->
<?yatt A ?>
<yatt:foo x y>
 <!--#yatt 2 -->
  <yatt:bar x y/>
<!--#yatt 3 -->
</yatt:foo>
BAZ
<!--#yatt 4 -->
<?yatt B ?>


<!yatt:widget foo x=list y="scalar?0">
FOO
<!--#yatt 1 -->
<?yatt A ?>
<yatt:foo x y>
 <!--#yatt 2 -->
  <yatt:bar x y/>
<!--#yatt 3 -->
</yatt:foo>
BAZ
<!--#yatt 4 -->
<?yatt B ?>
END

  {
    my $name = '';
    is ref (my $w = $tmpl->{Item}{$name}), 'YATT::Lite::Core::Widget'
      , "tmpl Item '$name'";
    eq_or_diff $tmpl->source_region
      ($w->{cf_startpos}, $w->{cf_bodypos})
	, qq{<!yatt:args x=list y="scalar?0">\n}, "part $name source_range decl";

    eq_or_diff $tmpl->source_substr($w->{cf_bodypos}, $w->{cf_bodylen})
      , q{FOO
<!--#yatt 1 -->
<?yatt A ?>
<yatt:foo x y>
 <!--#yatt 2 -->
  <yatt:bar x y/>
<!--#yatt 3 -->
</yatt:foo>
BAZ
<!--#yatt 4 -->
<?yatt B ?>


}, "part $name source_range body";

    my @test
      = ([2, q|<?yatt A ?>|]
	 , [4, q{<yatt:foo x y>
 <!--#yatt 2 -->
  <yatt:bar x y/>
<!--#yatt 3 -->
</yatt:foo>}]
	 , [7, q|<?yatt B ?>|]
	);

    foreach my $test (@test) {
      my ($i, $want) = @$test;
      is $tmpl->node_source($w->{tree}[$i]), $want
	, "render_$name node $i ($want)";
    }

    # print STDERR alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), "\n";exit;

    eq_or_diff alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), <<'END';
[
-
 FOO
 
{
kind: COMMENT
path: yatt
source:
 <!--#yatt 1 -->
 
value:
  1 
}
{
kind: PI
path[
- yatt
]
source: <?yatt A ?>
value:
  A 
}
-
 
 
{
kind: ELEMENT
path[
yatt: foo
]
source: <yatt:foo x y>
  <!--#yatt 2 -->
   <yatt:bar x y/>
 <!--#yatt 3 -->
 </yatt:foo>
subtree[
{
kind: ATTRIBUTE
path: x
source: x
value= #null
}
{
kind: ATTRIBUTE
path: y
source: y
value= #null
}
-
 
 
-
  
{
kind: COMMENT
path: yatt
source:
 <!--#yatt 2 -->
 
value:
  2 
}
-
   
{
kind: ELEMENT
path[
yatt: bar
]
source: <yatt:bar x y/>
subtree[
{
kind: ATTRIBUTE
path: x
source: x
value= #null
}
{
kind: ATTRIBUTE
path: y
source: y
value= #null
}
]
}
-
 
 
{
kind: COMMENT
path: yatt
source:
 <!--#yatt 3 -->
 
value:
  3 
}
]
}
-
 
 BAZ
 
{
kind: COMMENT
path: yatt
source:
 <!--#yatt 4 -->
 
value:
  4 
}
{
kind: PI
path[
- yatt
]
source: <?yatt B ?>
value:
  B 
}
-
 
 
]
END

  }

  {
    my $name = 'foo';
    is ref (my $w = $tmpl->{Item}{$name}), 'YATT::Lite::Core::Widget'
      , "tmpl Item '$name'";
    eq_or_diff $tmpl->source_region
      ($w->{cf_startpos}, $w->{cf_bodypos})
	, qq{<!yatt:widget foo x=list y="scalar?0">\n}, "part $name source_range decl";

    eq_or_diff $tmpl->source_substr($w->{cf_bodypos}, $w->{cf_bodylen})
      , q{FOO
<!--#yatt 1 -->
<?yatt A ?>
<yatt:foo x y>
 <!--#yatt 2 -->
  <yatt:bar x y/>
<!--#yatt 3 -->
</yatt:foo>
BAZ
<!--#yatt 4 -->
<?yatt B ?>
}, "part $name source_range body";

    my @test
      = ([2, q|<?yatt A ?>|]
	 , [4, q{<yatt:foo x y>
 <!--#yatt 2 -->
  <yatt:bar x y/>
<!--#yatt 3 -->
</yatt:foo>}]
	 , [7, q|<?yatt B ?>|]
	);

    foreach my $test (@test) {
      my ($i, $want) = @$test;
      is $tmpl->node_source($w->{tree}[$i]), $want
	, "render_$name node $i ($want)";
    }

    # print STDERR alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), "\n";exit;
    eq_or_diff alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), <<'END';
[
-
 FOO
 
{
kind: COMMENT
path: yatt
source:
 <!--#yatt 1 -->
 
value:
  1 
}
{
kind: PI
path[
- yatt
]
source: <?yatt A ?>
value:
  A 
}
-
 
 
{
kind: ELEMENT
path[
yatt: foo
]
source: <yatt:foo x y>
  <!--#yatt 2 -->
   <yatt:bar x y/>
 <!--#yatt 3 -->
 </yatt:foo>
subtree[
{
kind: ATTRIBUTE
path: x
source: x
value= #null
}
{
kind: ATTRIBUTE
path: y
source: y
value= #null
}
-
 
 
-
  
{
kind: COMMENT
path: yatt
source:
 <!--#yatt 2 -->
 
value:
  2 
}
-
   
{
kind: ELEMENT
path[
yatt: bar
]
source: <yatt:bar x y/>
subtree[
{
kind: ATTRIBUTE
path: x
source: x
value= #null
}
{
kind: ATTRIBUTE
path: y
source: y
value= #null
}
]
}
-
 
 
{
kind: COMMENT
path: yatt
source:
 <!--#yatt 3 -->
 
value:
  3 
}
]
}
-
 
 BAZ
 
{
kind: COMMENT
path: yatt
source:
 <!--#yatt 4 -->
 
value:
  4 
}
{
kind: PI
path[
- yatt
]
source: <?yatt B ?>
value:
  B 
}
-
 
 
]
END

  }
}

{
  my $tmpl = $CLASS->Template->new;
  $CLASS->load_string_into($tmpl, my $cp = <<END, all => 1);
<!yatt:args x>
<h2>Hello</h2>
<yatt:if "not defined &yatt:x;"> space!
<:yatt:else if="&yatt:x; >= 2"/> world!
<:yatt:else/> decades!
</yatt:if>
END

  my $name = '';
  is ref (my $w = $tmpl->{Item}{$name}), 'YATT::Lite::Core::Widget'
    , "tmpl Item '$name'";

  TODO: {
    # local $TODO = "Not yet solved";
    # print STDERR alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), "\n";exit;

    eq_or_diff alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), <<'END';
[
-
 <h2>Hello</h2>
 
{
kind: ELEMENT
path[
yatt: if
]
source: <yatt:if "not defined &yatt:x;"> space!
 <:yatt:else if="&yatt:x; >= 2"/> world!
 <:yatt:else/> decades!
 </yatt:if>
subtree[
{
kind: ATT_TEXT
path= #null
source: "not defined &yatt:x;"
subtree[
-
 not defined 
{
kind: entpath
source: &yatt:x;
subtree[
{
kind: var
path: x
source: :x
}
]
}
]
}
-
  space!
 
{
kind: ATT_NESTED
path[
yatt: else
]
source:
 <:yatt:else if="&yatt:x; >= 2"/> world!
 
subtree[
{
kind: ATT_TEXT
path: if
source: if="&yatt:x; >= 2"
subtree[
{
kind: entpath
source: &yatt:x;
subtree[
{
kind: var
path: x
source: :x
}
]
}
-
  >= 2
]
symbol_range{
end{
character: 14
line: 3
}
start{
character: 12
line: 3
}
}
}
-
  world!
 
]
}
{
kind: ATT_NESTED
path[
yatt: else
]
source:
 <:yatt:else/> decades!
 
subtree[
-
  decades!
-
 
 
]
}
]
}
-
 
 
]
END

  }
}

{
  my $tmpl = $CLASS->Template->new;
  $CLASS->load_string_into($tmpl, my $cp = <<END, all => 1);
<!yatt:args>
<yatt:foo a='
' b="
" />
<?perl===undef?>
<!yatt:widget foo a b >
END

  my $name = '';
  is ref (my $w = $tmpl->{Item}{$name}), 'YATT::Lite::Core::Widget'
    , "tmpl Item '$name'";

  {
    # print STDERR alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), "\n";exit;

    eq_or_diff alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), <<'END';
[
{
kind: ELEMENT
path[
yatt: foo
]
source: <yatt:foo a='
 ' b="
 " />
subtree[
{
kind: ATT_TEXT
path: a
source: a='
 '
symbol_range{
end{
character: 11
line: 1
}
start{
character: 10
line: 1
}
}
value:
 
 
}
{
kind: ATT_TEXT
path: b
source: b="
 "
symbol_range{
end{
character: 3
line: 2
}
start{
character: 2
line: 2
}
}
value:
 
 
}
]
}
-
 
 
{
kind: PI
path[
- perl
]
source: <?perl===undef?>
value: ===undef
}
-
 
 
]
END

  }
}

{
  my $tmpl = $CLASS->Template->new;
  $CLASS->load_string_into($tmpl, my $cp = <<END, all => 1);
<yatt:foo

--  foo ---

/>
<?perl===undef?>
END

  my $name = '';
  is ref (my $w = $tmpl->{Item}{$name}), 'YATT::Lite::Core::Widget'
    , "tmpl Item '$name'";

  {
    # print STDERR alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), "\n";

    eq_or_diff alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), <<'END';
[
{
kind: ELEMENT
path[
yatt: foo
]
source: <yatt:foo
 
 --  foo ---
 
 />
subtree[
]
}
-
 
 
{
kind: PI
path[
- perl
]
source: <?perl===undef?>
value: ===undef
}
-
 
 
]
END

}
}

{
  my $tmpl = $CLASS->Template->new;
  $CLASS->load_string_into($tmpl, my $cp = <<END, all => 1);
<yatt:foo>
<yatt:bar>
&yatt:x;
</yatt:bar>
</yatt:foo>

<!yatt:widget foo>
<yatt:body/>
<!yatt:widget bar body = [code x=html]>
<yatt:body/>
END

  my $name = '';
  is ref (my $w = $tmpl->{Item}{$name}), 'YATT::Lite::Core::Widget'
    , "tmpl Item '$name'";

  # print STDERR alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), "\n";

  eq_or_diff alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), <<'END';
[
{
kind: ELEMENT
path[
yatt: foo
]
source: <yatt:foo>
 <yatt:bar>
 &yatt:x;
 </yatt:bar>
 </yatt:foo>
subtree[
-
 
 
{
kind: ELEMENT
path[
yatt: bar
]
source: <yatt:bar>
 &yatt:x;
 </yatt:bar>
subtree[
-
 
 
{
kind: entpath
source: &yatt:x;
subtree[
{
kind: var
path: x
source: :x
}
]
}
- 
-
 
 
]
}
- 
-
 
 
]
}
-
 
 
]
END

}

{
  my $tmpl = $CLASS->Template->new;
  $CLASS->load_string_into($tmpl, my $cp = <<END, all => 1);
<yatt:my [code:code src:source]>
  <h2>&yatt:x;</h2>
  &yatt:y;
</yatt:my>
END

  my $name = '';
  is ref (my $w = $tmpl->{Item}{$name}), 'YATT::Lite::Core::Widget'
    , "tmpl Item '$name'";

  #print STDERR alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), "\n";exit;

  eq_or_diff alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), <<'END';
[
{
kind: ELEMENT
path[
yatt: my
]
source: <yatt:my [code:code src:source]>
   <h2>&yatt:x;</h2>
   &yatt:y;
 </yatt:my>
subtree[
{
kind: ATT_NESTED
path= #null
source: [code:code src:source]
subtree[
{
kind: ATTRIBUTE
path[
code: code
]
source: code:code
value= #null
}
{
kind: ATTRIBUTE
path[
src: source
]
source: src:source
value= #null
}
]
}
-
 
 
-
   <h2>
{
kind: entpath
source: &yatt:x;
subtree[
{
kind: var
path: x
source: :x
}
]
}
-
 </h2>
 
-
   
{
kind: entpath
source: &yatt:y;
subtree[
{
kind: var
path: y
source: :y
}
]
}
- 
-
 
 
]
}
-
 
 
]
END


}

if (1) {
  my $tmpl = $CLASS->Template->new;
  $CLASS->load_string_into($tmpl, my $cp = <<END, all => 1);
<h2>&yatt[[;Hello &yatt:world;!&yatt]];</h2>

<p>&yatt#num[[;
  &yatt:n; file removed from directory &yatt:dir;
&yatt||;
  &yatt:n; files removed from directory &yatt:dir;
&yatt]];</p>
END

  my $name = '';
  is ref (my $w = $tmpl->{Item}{$name}), 'YATT::Lite::Core::Widget'
    , "tmpl Item '$name'";

  # print STDERR alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), "\n";

  eq_or_diff alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), <<'END';
[
- <h2>
{
kind: LCMSG
path[
- yatt
]
source: &yatt[[;Hello &yatt:world;!&yatt]];
subtree[
-
 Hello 
{
kind: entpath
source: &yatt:world;
subtree[
{
kind: var
path: world
source: :world
}
]
}
- !
]
}
-
 </h2>
 
-
 
 
- <p>
{
kind: LCMSG
path[
yatt: num
]
source: &yatt#num[[;
   &yatt:n; file removed from directory &yatt:dir;
 &yatt||;
   &yatt:n; files removed from directory &yatt:dir;
 &yatt]];
subtree[
-
 
 
-
   
{
kind: entpath
source: &yatt:n;
subtree[
{
kind: var
path: n
source: :n
}
]
}
-
  file removed from directory 
{
kind: entpath
source: &yatt:dir;
subtree[
{
kind: var
path: dir
source: :dir
}
]
}
-
 
 
]
}
- </p>
-
 
 
]
END


}

{
  my $tmpl = $CLASS->Template->new;
  my $err = catch {$CLASS->load_string_into($tmpl, my $cp = <<END, all => 1)};
<yatt:my [x y :::z]="1..8"; />
END

  like $err, qr{^\QGarbage before CLO(>) for: <yatt:my, rest: '; />'}
    , "Garbage before CLO(>) should be rejected by LRXML parser";
}

{
  my $tmpl = $CLASS->Template->new;
  $CLASS->load_string_into($tmpl, my $cp = <<END, all => 1);
<yatt:my [x y :::z]="1..8" />
x=&yatt:x;
y=&yatt:y;
z=&yatt:z;
END

  my $name = '';
  is ref (my $w = $tmpl->{Item}{$name}), 'YATT::Lite::Core::Widget'
    , "tmpl Item '$name'";

  # print STDERR alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), "\n";

  TODO: {
    local $TODO = "Not yet solved";
    eq_or_diff alt_tree_xhf_for($tmpl->{cf_string}, $w->{tree}), <<'END';
[
{
kind: ELEMENT
path[
yatt: my
]
source: <yatt:my [x y :::z]="1..8" />
subtree[
{
kind: ATT_TEXT
path[
{
kind: ATTRIBUTE
path: x
source: x
value= #null
}
{
kind: ATTRIBUTE
path: y
source: y
value= #null
}
{
kind: ATTRIBUTE
path[
- 
- 
- 
- z
]
source: :::z
value= #null
}
]
source: [x y :::z]="1..8"
symbol_range{
end{
character: 28
line: 0
}
start{
character: 8
line: 0
}
}
value: 1..8
}
]
}
-
 
 
- x=
{
kind: entpath
source: &yatt:x;
subtree[
{
kind: var
path: x
source: :x
}
]
}
-
 
 
- y=
{
kind: entpath
source: &yatt:y;
subtree[
{
kind: var
path: y
source: :y
}
]
}
-
 
 
- z=
{
kind: entpath
source: &yatt:z;
subtree[
{
kind: var
path: z
source: :z
}
]
}
-
 
 
]
END

  }

}

{
  my $tmpl = $CLASS->Template->new;
  eval {
    $CLASS->load_string_into($tmpl, my $cp = <<END, all => 1);
<!yatt:args

END
  };
  like $@, qr/^Declarator '<!yatt:args' is not closed with '>'/
    , "Unclosed <!yatt:args";
}

{
  my $tmpl = $CLASS->Template->new;
  eval {
    $CLASS->load_string_into($tmpl, my $cp = <<END, all => 1);
<!yatt:args
&yatt:foo;
END
  };
  like $@, qr/^yatt:args got wrong token for route spec: ENTITY/, "Unclosed <!yatt:args\\n &yatt:foo;";
}

{
  my $tmpl = $CLASS->Template->new;
  eval {
    $CLASS->load_string_into($tmpl, my $cp = <<END, all => 1);
<!yatt:widget
&yatt:foo;
END
  };
  like $@, qr/^yatt:widget got wrong token for route spec: ENTITY/, "Unclosed <!yatt:widget\\n &yatt:foo;";
}

# (- (region-end) (region-beginning))
#
done_testing();
