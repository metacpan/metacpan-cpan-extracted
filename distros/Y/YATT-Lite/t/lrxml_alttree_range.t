#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use constant DEBUG_DUMP_TREE => $ENV{DEBUG_DUMP_TREE};

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
    with_range => 1,
  )->convert_tree($tree)];
}
sub alt_tree_xhf_for {
  my $str = YATT::Lite::XHF::Dumper->dump_strict_xhf(alt_tree_for(@_))."\n";
  print STDERR $str if DEBUG_DUMP_TREE;
  $str;
}


my $CLASS = 'YATT::Lite::LRXML';
use_ok($CLASS);


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
tree_range{
end{
character: 11
line: 2
}
start{
character: 10
line: 2
}
}
value= #null
}
{
kind: ATTRIBUTE
path: y
source: y
tree_range{
end{
character: 13
line: 2
}
start{
character: 12
line: 2
}
}
value= #null
}
-
 
 
- bar
-
 
 
]
symbol_range{
end{
character: 8
line: 2
}
start{
character: 0
line: 2
}
}
tree_range{
end{
character: 11
line: 4
}
start{
character: 0
line: 2
}
}
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
symbol_range{
end{
character: 11
line: 8
}
start{
character: 9
line: 8
}
}
tree_range{
end{
character: 11
line: 8
}
start{
character: 9
line: 8
}
}
}
]
tree_range{
end{
character: 12
line: 8
}
start{
character: 4
line: 8
}
}
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
symbol_range{
end{
character: 7
line: 9
}
start{
character: 5
line: 9
}
}
tree_range{
end{
character: 7
line: 9
}
start{
character: 5
line: 9
}
}
}
]
tree_range{
end{
character: 8
line: 9
}
start{
character: 0
line: 9
}
}
}
-
 
 
]
END

  }
}

sub eq_or_diff_of_lrxml_alt_tree_with_xhf ($$) {
  my ($lrxml, $xhf) = @_;
  my ($callpack, $file, $line) = caller;
  my $parser = $CLASS->new(all => 1);
  my $tmpl = $CLASS->Template->new;
  $parser->load_string_into($tmpl, $lrxml);

  my $w = $tmpl->{Item}{''};
  eq_or_diff alt_tree_xhf_for($lrxml, $w->{tree}), $xhf, "at line: $line";
}

{
  eq_or_diff_of_lrxml_alt_tree_with_xhf <<'END_SOURCE', <<'END_DUMP';
<!yatt:args foo bar baz>
&yatt:foo:bar:baz;
END_SOURCE
[
{
kind: entpath
source: &yatt:foo:bar:baz;
subtree[
{
kind: var
path: foo
source: :foo
symbol_range{
end{
character: 9
line: 1
}
start{
character: 5
line: 1
}
}
tree_range{
end{
character: 9
line: 1
}
start{
character: 5
line: 1
}
}
}
{
kind: prop
path: bar
source: :bar
symbol_range{
end{
character: 14
line: 1
}
start{
character: 9
line: 1
}
}
tree_range{
end{
character: 13
line: 1
}
start{
character: 9
line: 1
}
}
}
{
kind: prop
path: baz
source: :baz
symbol_range{
end{
character: 18
line: 1
}
start{
character: 13
line: 1
}
}
tree_range{
end{
character: 17
line: 1
}
start{
character: 13
line: 1
}
}
}
]
tree_range{
end{
character: 18
line: 1
}
start{
character: 0
line: 1
}
}
}
-
 
 
]
END_DUMP

}

{
  eq_or_diff_of_lrxml_alt_tree_with_xhf <<'END_SOURCE', <<'END_DUMP';
<!yatt:args foo bar baz>
&yatt:foo(xxx,:bar(:baz),yyy);
END_SOURCE
[
{
kind: entpath
source: &yatt:foo(xxx,:bar(:baz),yyy);
subtree[
{
kind: call
path: foo
source: :foo(xxx,:bar(:baz),yyy)
subtree[
{
kind: call
path: bar
source: :bar(:baz)
subtree[
{
kind: var
path: baz
source: :baz
symbol_range{
end{
character: 23
line: 1
}
start{
character: 19
line: 1
}
}
tree_range{
end{
character: 23
line: 1
}
start{
character: 19
line: 1
}
}
}
]
symbol_range{
end{
character: 19
line: 1
}
start{
character: 14
line: 1
}
}
tree_range{
end{
character: 24
line: 1
}
start{
character: 14
line: 1
}
}
}
]
symbol_range{
end{
character: 10
line: 1
}
start{
character: 5
line: 1
}
}
tree_range{
end{
character: 29
line: 1
}
start{
character: 5
line: 1
}
}
}
]
tree_range{
end{
character: 30
line: 1
}
start{
character: 0
line: 1
}
}
}
-
 
 
]
END_DUMP

}

done_testing();
