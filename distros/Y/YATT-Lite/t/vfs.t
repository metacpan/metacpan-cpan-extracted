#!/usr/bin/perl -w
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use File::Temp qw(tempdir);
use autodie qw(mkdir chdir);

use Getopt::Long;
GetOptions('q|quiet' => \ (my $quiet))
  or die "Unknown options\n";

sub TestFiles () {'YATT::Lite::Test::TestFiles'}
require_ok(TestFiles);
sub VFS () {'YATT::Lite::VFS'}
require_ok(VFS);

{
  package DummyFacade; sub MY () {__PACKAGE__}
  use base qw(YATT::Lite::Object);
  use fields qw/cf_opts/;
  sub error {
    shift; die @_;
  }
  sub create_neighbor {
    (my MY $self, my $dir) = @_;
    YATT::Lite::VFS->new([dir => $dir], facade => $self, @{$self->{cf_opts}})
	->root;
  }
}

# Use .tmpl instead of .ytmpl
my @CF_main = (ext_private => 'tmpl', ext_public => 'yatt');
my @CF = (@CF_main, facade => DummyFacade->new(opts => \@CF_main));

my ($i, $theme);

#========================================

$theme = "(mem) plain";

# * data => HASH
# * base => [[data => HASH] ...]
#========================================

{
  my $vfs = VFS->new
    ([data => {foo => 'mytext'
	       , baz => {item => 'nested'}
	     }, base => [[data => {'bar' => 'BARRR'}]]]
     , no_auto_create => 1, @CF);
  is $vfs->find_part('foo'), 'mytext', "$theme - foo";
  is $vfs->find_part('bar'), 'BARRR', "$theme - bar";
  is_deeply $vfs->find_part('baz'), {item => 'nested'}, "$theme - nested item";
}

#========================================
# * VFS->create($kind => $spec)
# * data => {name => VFS}

$theme = "(mem) from nested Dir";
#----------------------------------------

{
  my $vfs = VFS->new
    ([data => {foo => VFS->create(data => {'bar' => 'BARRR'})}
      , base => [[data => {foo => VFS->create(data => {'baz' => 'ZZZ'})}]]]
     , no_auto_create => 1, @CF);
  is $vfs->find_part('foo', 'bar'), 'BARRR', "$theme - foo bar";
  is $vfs->find_part('foo', 'baz'), 'ZZZ', "$theme - foo baz";
}

# ========================================
# * data => {name => {name => string}}

$theme = "(mem) auto create for nested data";
{
  my $vfs = VFS->new
    ([data => {foo => 'mytext'
	       , baz => {item => 'nested'}
	     }, base => [[data => {'bar' => 'BARRR'}]]]
     , @CF);
  is $vfs->find_part('foo')->cget('string'), 'mytext', "$theme - foo";
  is $vfs->find_part('bar')->cget('string'), 'BARRR', "$theme - bar";
  is $vfs->find_part('baz', 'item')->cget('string'), 'nested', "$theme - nested item";
}


#========================================
# * [dir => $dir]
# * multipart (file foo contains widget bar)

$i = 1; $theme = "[t$i] from dir";
#----------------------------------------

my $BASE = tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1);
END {
  chdir('/');
}

{
  my $dir = TestFiles->new("$BASE/t$i", quiet => $quiet);
  $dir->add('foo.yatt', <<'END');
AAA
BBB
! widget bar
barrrr
END

  $dir->add('base.yatt', <<'END');
! widget qux
Q
! widget quux
QQ
END

}
{
  ok chdir(my $cwd = "$BASE/t". $i), "chdir [t$i]";
  my $root = VFS->new([dir => $cwd], @CF);
  is $root->find_part('foo', ''), "AAA\nBBB\n", "$theme - foo ''";
  is $root->find_part('foo', 'bar'), "barrrr\n", "$theme - foo bar";
  is_deeply [sort $root->list_items]
    , [qw/base foo/]
      , "$theme - list_items";
}

#========================================
# * [dir => $dir, base => [[file => $file]]
#   directory can inherit parts from a file

$theme = "[t$i] base file";
#----------------------------------------

{

  ok chdir(my $cwd = "$BASE/t". $i), "chdir [t$i]";
  my $root = VFS->new([dir => $cwd
			     , base => [[file => "$cwd/base.yatt"]]]
			    , @CF);
  is $root->find_part('qux'), "Q\n", "$theme - qux";
  is $root->find_part('quux'), "QQ\n", "$theme - quux";
}

#========================================
# * base declaration in file foo.yatt inherits base.yatt

$i = 2; $theme = "[t$i] ! base";
#----------------------------------------

{
  my $dir = TestFiles->new("$BASE/t$i", quiet => $quiet);

  $dir->add('foo.yatt', <<'END');
! base file=base.yatt
AAA
BBB
! widget bar
barrrr
END


  #
  $dir->add('base.yatt', <<'END');
! widget baz
CCC
DDD
! widget qux
EEE
! widget quux
FFF
END

  #
}

{
  ok chdir(my $cwd = "$BASE/t". $i), "chdir [t$i]";
  my $root = VFS->new([dir => $cwd], @CF);
  is $root->find_part('foo', ''), "AAA\nBBB\n", "$theme - foo";
  is $root->find_part('foo', 'bar'), "barrrr\n", "$theme - foo bar";
  is $root->find_part('foo', 'baz'), "CCC\nDDD\n", "$theme - baz";
}

sub D {
  require Data::Dumper;
  join " ", Data::Dumper->new([@_])->Terse(1)->Indent(0)->Dump;
}


#========================================
# !base dir=base.tmpl
$i = 3; $theme = "[t$i] base dir (in template)";
#----------------------------------------

{
  my $dir = TestFiles->new("$BASE/t$i", quiet => $quiet);
  $dir->add('foo.yatt', <<END);
! base dir=base.tmpl
AAA
END

  {
    my $base = $dir->mkdir('base.tmpl');

    $dir->add("$base/bar.yatt", <<END);
BBB
! widget qux
EEE
END

    $dir->add("$base/baz.yatt", <<END);
CCC
END
  }
}

{
  ok chdir(my $cwd = "$BASE/t". $i), "chdir [t$i]";
  my $root = VFS->new([dir => $cwd], @CF); my @x;
  is $root->find_part(@x = ('foo', '')), "AAA\n", "$theme - ".D(@x);
  is $root->find_part(@x = ('foo', 'bar', '')), "BBB\n", "$theme - ".D(@x);
  is $root->find_part(@x = ('foo', 'baz', '')), "CCC\n", "$theme - ".D(@x);
}

#========================================
# base in VFS->new([dir => $dir, base => [[dir => base.tmpl]]])
# keeps $i.

$theme = "[t$i] base dir (in VFS new)";
#----------------------------------------

{
  ok chdir(my $cwd = "$BASE/t". $i), "chdir [t$i]"; my @x;
  my $root = VFS->new([dir => $cwd, base => [[dir => "$cwd/base.tmpl"]]], @CF);
  is $root->find_part(@x = ('bar', '')), "BBB\n", "$theme - ".D(@x);
  is $root->find_part(@x = ('baz', '')), "CCC\n", "$theme - ".D(@x);
}

#========================================
$i++; $theme = "[t$i] base dir (in VFS new and !base)";
#----------------------------------------

{
  my $dir = TestFiles->new("$BASE/t$i", quiet => $quiet);
  $dir->mkdir('doc');
  $dir->add('doc/foo.yatt', <<END);
AAA
END

  $dir->add('doc/bar.yatt', <<END);
! base dir=quux.tmpl
BBB
! widget quuuuux
EEE
END

  $dir->add($dir->mkdir('qux.tmpl') . "/baz.yatt", <<END);
CCC
END

  $dir->add($dir->mkdir('quux.tmpl') . "/baz.yatt", <<END);
DDD
END
}
{
  ok chdir(my $cwd = "$BASE/t". $i), "chdir [t$i]"; my @x;
  my $root = VFS->new([dir => "$cwd/doc"
		       , base => [[dir => "$cwd/qux.tmpl"]]], @CF);
  is $root->find_part(@x = ('foo', '')), "AAA\n", "$theme - ".D(@x);
  is $root->find_part(@x = ('foo', 'baz', '')), "CCC\n", "$theme - ".D(@x);
  is $root->find_part(@x = ('bar', 'baz', '')), "DDD\n", "$theme - ".D(@x);
  is $root->find_part(@x = ('bar', 'quuuuux')), "EEE\n", "$theme - ".D(@x);
}

#========================================
$i++; $theme = "[t$i] coexisting foo.yatt and foo/";
#----------------------------------------

{
  my $dir = TestFiles->new("$BASE/t$i", quiet => $quiet);
  $dir->add('foo.yatt', <<'END');
! base file=base.tmpl
AAA
BBB
! widget bar
CCC
END

  $dir->add((my $foo = $dir->mkdir('foo')) . "/bar.yatt", <<'END');
DDD
END

  $dir->add("$foo/baz.yatt", <<'END');
EEE
END

  $dir->add('qux.yatt', <<'END');
FFF
END

  $dir->add("$foo/qux.yatt", <<'END');
GGG
END

  $dir->add('base.tmpl', <<'END');
! widget hoehoe
HHH
! widget moemoe
III
END


}

{
  ok chdir(my $cwd = "$BASE/t". $i), "chdir [t$i]";
  my $root = VFS->new([dir => $cwd], @CF);
  my $foo = $root->find_part('foo');
  is $root->find_part_from($foo, 'bar'), "CCC\n", "$theme bar (template wins)";
  is $root->find_part_from($foo, 'baz'), "EEE\n", "$theme baz (dir is merged)";
  is $root->find_part_from($foo, 'qux'), "FFF\n", "$theme qux (cwd wins)";
  is $root->find_part_from($foo, 'hoehoe'), "HHH\n", "$theme base is merged";
}

#========================================
$i++; $theme = "[t$i] widget in subdir file";
#----------------------------------------

{
  my $dir = TestFiles->new("$BASE/t$i", quiet => $quiet);
  $dir->add('foo.yatt', 'AAA');

  $dir->add((my $bar = $dir->mkdir('bar')) . "/baz.yatt", <<'END');
! widget qux
PPP
! widget quux
QQQ
END
}

{
  ok chdir(my $cwd = "$BASE/t". $i), "chdir [t$i]";
  my $root = VFS->new([dir => $cwd], @CF);
  my $foo = $root->find_part('foo');

  is $root->find_part_from($foo, 'bar', 'baz', 'qux'), "PPP\n"
    , "$theme bar:baz:qux can be refered from foo";
}

done_testing();
