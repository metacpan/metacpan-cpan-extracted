#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

#
# Note: To see generated perl codes, run this test with DEBUG=2.
#

use Test::More;
use YATT::Lite::Test::TestUtil;

use YATT::Lite::Constants;
require_ok('YATT::Lite');

use YATT::Lite::Util qw(appname);
sub myapp {join _ => MyTest => appname($0), @_}

our @res;
sub run_list {
  my ($theme, $list, $obj, $method, @args) = @_;
  open my $fh, ">", \ (my $buf = "") or die $!;
  @res = ();
  eval {$obj->$method($fh, @args)};
  if ($@) {
    fail "$theme $@";
  } else {
    is scalar @res, scalar @$list, "$theme res.len vs list.len";
    my $i = 0;
    foreach my $res (@res) {
      ok($res->[0], "$theme.$i $res->[2] == __LINE__ (runtime ==)");
      is($res->[1], $res->[2], "$theme.$i __LINE__ is $res->[2] (external 'is')");
    } continue {$i++}
  }
}

# 行番号が一致したら BYE, を差し込む。
sub inject {
  my ($text, $listvar) = @_;
  $text =~ s{(?=<!--(\d+)-->)}{
    push @$listvar, $1;
    sprintf q{<?perl push @main::res, [%1$s == __LINE__, __LINE__, %1$s]?>}, $1;
  }eg;
  $text;
}

sub is_debugging {
  my $glob = $main::{'DB::'} or return;
  my $stash = *{$glob}{HASH} or return;
  defined $stash->{'cmd'};
}

my @OPT = (no_lineinfo => $ENV{NO_LINEINFO} // is_debugging()
	   , debug_cgen => $ENV{DEBUG});

my $test_widget_lineno = sub {
  my ($yatt, $THEME, @test) = @_;
  foreach my $test (@test) {
    my ($name, $region, %call) = @$test;
    my $part = $yatt->find_part('index', $name);
    is $part->{cf_startln}, $region->[0]
      , "$THEME widget '$name' startln == $region->[0]";
    is $part->{cf_endln}, $region->[1]
      , "$THEME widget '$name' endln == $region->[1]";
    foreach my $tok (@{$part->{tree}}) {
      next unless ref $tok and $tok->[NODE_TYPE] == TYPE_ELEMENT;
      my $callpath = join ":", @{$tok->[NODE_PATH]};
      is $tok->[NODE_LNO], $call{$callpath}
	, "$THEME widget call $callpath lineno = $call{$callpath}";
    }
  }
  
};

my $i = 1;
{
  my $THEME = "basic";
  my $yatt = new YATT::Lite(app_ns => myapp($i), vfs => [data => {}], @OPT);
  my $SUB = 'index';
  ok(my $tmpl = $yatt->add_to($SUB => inject <<'END', \ my @list)
<!yatt:args x y>
<!--2-->
<yatt:foo />
<!--4-->
<yatt:baz />
<!yatt:widget foo >
<!--7-->
bar

<!yatt:widget baz >
<!--11-->qux


END
     , "$THEME - add_to $SUB");

  my $pkg = $yatt->find_product(perl => $tmpl);
  $test_widget_lineno->($yatt, $THEME
			, ['' => [1, 6], 'yatt:foo' => 3, 'yatt:baz' => 5]
			, [foo => [6, 10]], [baz => [10, 14]]);
  run_list($THEME, \@list, $pkg, render_ => ());
}
# "\n";

$i = 2;
# コメント
{
  my $THEME = "comment";
  my $yatt = new YATT::Lite(app_ns => myapp($i)
			    , vfs => [data => {}], @OPT);
  my $SUB = 'index';
  ok(my $tmpl = $yatt->add_to($SUB => inject <<'END', \ my @list)
<!yatt:args  x y>

<!--#yatt
<!yatt:widget foo >
-->
<yatt:foo /><!--6-->
<!--#yatt
<!yatt:widget bar >
--><!--9-->

<!yatt:widget foo >
<!--12-->bar
END
     , "$THEME - add_to $SUB");

  my $pkg = $yatt->find_product(perl => $tmpl);
  $test_widget_lineno->($yatt, $THEME
			, ['' => [1, 11], 'yatt:foo' => 6]
			, [foo => [11, 13]]);
  run_list($THEME, \@list, $pkg, render_ => ());
}
# 引数リスト
$i = 3;
{
  my $THEME = "newline in arg decls";
  my $yatt = new YATT::Lite(app_ns => myapp($i), vfs => [data => {}], @OPT);
  my $SUB = 'index';
  ok(my $tmpl = $yatt->add_to($SUB => inject <<'END', \ my @list)
<!yatt:args
    x=text
    y=value
>
<!--5-->
<yatt:foo  x y/>

<!yatt:widget
  foo
  x y
   =
  "html?
foo
bar
"
z>
<!--17-->bar
END
     , "$THEME - add_to $SUB");

  my $pkg = $yatt->find_product(perl => $tmpl);
  foreach my $test (['' => [x => 2], [y => 3]]) {
    my ($name, @args) = @$test;
    my $part = $yatt->find_part('index', $name);
    foreach my $arginfo (@args) {
      my ($arg, $lineno) = @$arginfo;
      is $part->{arg_dict}{$arg}->lineno, $lineno, "$THEME arg $arg";
    }
  }
  run_list($THEME, \@list, $pkg, render_ => 'myx', 'myY');
}

$i = 4;
{
  my $THEME = "newline in call args (bodyless)";
  my $yatt = new YATT::Lite(app_ns => myapp($i), vfs => [data => {}], @OPT);
  my $SUB = 'index';
  ok(my $tmpl = $yatt->add_to($SUB => inject <<'END', \ my @list)
<!yatt:args  x y>

<yatt:foo
  x
  y
/>
<!--7-->

<!yatt:widget foo  x y>
<!--10-->bar
END
     , "$THEME - add_to $SUB");

  my $pkg = $yatt->find_product(perl => $tmpl);
 TODO: {
    local our $TODO = "Perl bug?" unless $] >= 5.012;
    run_list($THEME, \@list, $pkg, render_ => 'myx', 'myY');
  }
}

# body

$i = 5;
{
  my $THEME = " body ";
  my $yatt = new YATT::Lite(app_ns => myapp($i), vfs => [data => {}], @OPT);
  my $SUB = 'index';
  ok(my $tmpl = $yatt->add_to($SUB => inject <<'END', \ my @list), "$THEME - add_to $SUB");
<!yatt:args  x y>
foo
<!--3-->
<yatt:bar  x y>
hoehoe
<!--6-->
</yatt:bar>
<!--8-->

<!yatt:widget bar  x y>
<div>
<!--12-->
<yatt:body />
<!--14-->
</div>
END

  is $yatt->find_part($SUB, 'bar')->{cf_startln}, 10, "$THEME-$SUB. bar lineno";

  my $pkg = $yatt->find_product(perl => $tmpl);
  run_list($THEME, \@list, $pkg, render_ => 'foo', 'bar');
}

$i = 6;
TODO: {
  local our $TODO = "Not yet addressed";
  my $THEME = "<?yatt?> before args";
  my $yatt = new YATT::Lite(app_ns => myapp($i), vfs => [data => {}], @OPT);
  my $SUB = 'index';
  ok(my $tmpl = $yatt->add_to($SUB => inject <<'END', \ my @list), "$THEME - add_to $SUB");
<?yatt
?>
<!yatt:args
   x
   y>
<!--5-->
END

  eval {
    my $pkg = $yatt->find_product(perl => $tmpl);
    run_list($THEME, \@list, $pkg, render_ => 'foo', 'bar');
  };
  is $@, undef, "$THEME no error";
}

$i = 7;
TODO: {
  local our $TODO = "Perl bug?";
  my $THEME = "elematt";
  my $yatt = new YATT::Lite(app_ns => myapp($i), vfs => [data => {}], @OPT);
  my $SUB = 'index';
  ok(my $tmpl = $yatt->add_to($SUB => inject <<'END', \ my @list), "$THEME - add_to $SUB");
<yatt:elematt>
<:yatt:title>TITLE</:yatt:title>
BODY<!--3-->
<:yatt:header/>
<!--5-->HEADER
<:yatt:footer/>
<!--7-->FOOTER
</yatt:elematt>
<!--9-->

<!yatt:widget elematt title=code header=code footer=code>
<head>
&yatt:header();
<title>&yatt:title();</title>
</head>
<body>
<h2>&yatt:title();</h2>
<div id=main>
<yatt:body/>
</div>
&yatt:footer();
</body>
END

  is $yatt->find_part($SUB, $THEME)->{cf_startln}, 11
     , "$THEME-$SUB. lineno";

  $yatt->ensure_parsed($yatt->find_part($SUB, ''));

  my $pkg = $yatt->find_product(perl => $tmpl);
  run_list($THEME, \@list, $pkg, render_ => ());
}

$i = 8;
{
  my $THEME = "envelope";
  my $yatt = new YATT::Lite(app_ns => myapp($i), vfs => [data => {}], @OPT);
  my $SUB = 'index';
  ok(my $tmpl = $yatt->add_to($SUB => inject <<'END', \ my @list), "$THEME - add_to $SUB");
<!yatt:args>
<yatt:envelope>
<:yatt:style>
h2 {
  background: #ccc;
}
</:yatt:style>
<!--8-->
BODY

<:yatt:footer/>
<!--12-->FOOTER
</yatt:envelope>

<!yatt:widget envelope style="html?" footer="code">
<!--16-->
<head>
<style>
&yatt:style;
</style>
</head>
<body>
<div id=main>
<yatt:body/>
</div>
&yatt:footer();
</body>
END

  is $yatt->find_part($SUB, $THEME)->{cf_startln}, 15
     , "$THEME-$SUB. lineno";

  $yatt->ensure_parsed($yatt->find_part($SUB, ''));

  my $pkg = $yatt->find_product(perl => $tmpl);
  run_list($THEME, \@list, $pkg, render_ => ());
}

$i = 9;
{
  my $THEME = "foreach";
  my $yatt = new YATT::Lite(app_ns => myapp($i), vfs => [data => {}], @OPT);
  my $SUB = 'index';
  ok(my $tmpl = $yatt->add_to($SUB => inject <<'END', \ my @list), "$THEME - add_to $SUB");
<!yatt:args list="list">

<table><!--3-->
<yatt:foreach my:list=row list>
<tr><!--5-->
<yatt:foreach my=col list=row>
<td><!--7-->
&yatt:col;
</td>
</yatt:foreach>
</tr><!--11-->
</yatt:foreach>
</table><!--13-->
END

  $yatt->ensure_parsed($yatt->find_part($SUB, ''));

  my $pkg = $yatt->find_product(perl => $tmpl);
  run_list($THEME, \@list, $pkg, render_ => ([["FOO"]]));
}

done_testing();
