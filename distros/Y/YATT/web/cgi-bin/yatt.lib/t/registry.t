#!/usr/bin/perl -w
# -*- mode: perl; coding: utf-8 -*-
use strict;
use warnings qw(FATAL all NONFATAL misc);
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin;
use lib "$FindBin::Bin/..";
use YATT::Test qw(no_plan);
use YATT::LRXML::Node;
use YATT::Util qw(catch default);

use File::stat;

require_ok('YATT::Registry');
&YATT::break_translator;

my $TMPDIR = tmpbuilder(rootname($0) . ".tmp");

my $SESSION = 1;
{
  my $DIR = $TMPDIR->([DIR => 'foo'
		       , [FILE => 'bar.html', q{<h2>bar.html</h2>}]],
		      [FILE => 'foo.html'
		       , q{<!yatt:widget bar>}]);

  my $root = new YATT::Registry(loader => [DIR => $DIR]
			       , auto_reload => 1);
  is $root->cget('age'), 1, "[$SESSION] root age";
  is_deeply [$root->list_ns], [qw(foo)], "[$SESSION] list_ns";
  run("[$SESSION] wid_by_nsname - no error", sub {
	is defined($root->widget_by_nsname($root, qw(foo bar))), 1
	  , "[$SESSION] wid_by_nsname";
      });

  is $root->cget('age'), 1, "[$SESSION] root age";
}

# [2]
{
  $SESSION++;
  my $DIR = $TMPDIR->([DIR => 'app'
		       , [FILE => 'foo.html', q{<h2>foo</h2>}]],
		      [DIR => 'lib1'
		       , [FILE => 'bar.html', q{<h2>bar</h2>}]]);

  my $root = new YATT::Registry(loader => [DIR => "$DIR/app"
					   , LIB => "$DIR/lib1"]
			       , auto_reload => 1);
  is_deeply [sort $root->list_ns], [qw(bar foo)], "[$SESSION] list_ns";
}

# [3]
{
  $SESSION++;
  my $DIR = $TMPDIR->
    ([DIR => 'app'
      , [FILE => '.htyattrc'
	 , q{use YATT::Registry base => '/normal'; sub foo {"FOO"}}]
      , [FILE => 'index.html', q{<h2>foo</h2>}]],
     [DIR => 'lib1'
      , [DIR => 'normal'
	 , [FILE => '.htyattrc', q{sub bar {"BAR"}}]
	 , [FILE => 'bar.html', q{<h2>bar</h2>}]]]);

  my $root = new YATT::Registry
    (loader => [DIR => "$DIR/app", LIB => "$DIR/lib1"]
     , app_prefix => "MyApp$SESSION"
     , auto_reload => 1);
  is_deeply [sort $root->list_ns], [qw(index normal)]
    , "[$SESSION] base => /normal";

  isnt my $index = $root->get_ns(['index']), undef, "[$SESSION] index";
  isnt $root->get_widget_from_template($index, qw(yatt bar)), undef
    , "[$SESSION] bar";

  my $top = $root->get_package($root);
  is_can [$top, 'foo'], "FOO", "[$SESSION] top->foo";
  is_can [$top, 'bar'], "BAR", "[$SESSION] top->bar";
  is $top, "MyApp$SESSION", "[$SESSION] top == class app_prefix";
}

# [4]
{
  $SESSION++;
  my $DIR = $TMPDIR->
    ([DIR => 'app'
      , [FILE => '.htyattrc'
	 , q{use YATT::Registry base => 'normal'; sub foo {"FOO"}}]
      , [FILE => 'index.html', q{<!yatt:base "simple">}]
      , [DIR  => 'normal'
	 , [FILE => 'simple.html', q{<!yatt:widget foo><h2>simple</h2>}]]]);

  my $root = new YATT::Registry
    (loader => [DIR => "$DIR/app"]
     , app_prefix => "MyApp$SESSION"
     , auto_reload => 1);

  isnt my $index = $root->get_ns(['index']), undef, "[$SESSION] index";
  isa_ok $index, $root->Template, "[$SESSION] index";
  isnt $root->get_widget_from_template($index, qw(yatt foo)), undef
    , "[$SESSION] foo";
}

# [5]
{
  require YATT::Types;
  import YATT::Types -base => 'YATT::Registry', [Base => []];

  $SESSION++;
  my $builder = $TMPDIR->as_sub;
  my $DIR = $builder->
    ([DIR => 'app'
      , [FILE => '.htyattrc'
	 , q{use YATT::Registry base => 'normal';
Entity bar => sub {'baz'};
}]
      , [FILE => 'index.html', q{<h2>hello</h2>}]
      , [DIR  => 'normal'
	 , [DIR  => 'simple'
	    , [FILE => 'widget.html', q{<h2>simple</h2>}]]]]);

  my $root = new YATT::Registry
    (loader => [DIR => "$DIR/app"]
     , app_prefix => "MyApp$SESSION"
     , default_base_class => Base()
     , auto_reload => 1);

  isnt my $index = $root->get_ns(['index']), undef, "[$SESSION] index";
  isa_ok $index, $root->Template, "[$SESSION] index";
  isnt $root->get_widget_from_template
    ($index, qw(yatt simple widget)), undef, "[$SESSION] simple widget";

  if (my $sleep = wait_for_time(stat("$DIR/app/index.html")->mtime + 1)) {
    print STDERR "# slept $sleep sec\n" if $ENV{VERBOSE};
  }

  $builder->([DIR => 'app'
	      # To make sure directory mtime is changed.
	      , [FILE => 'new.tmp', q{}]

	      , [FILE => 'index.html', q{<h2>world</h2>}]
	      , [FILE => '.htyattrc', q{use YATT::Registry base => 'normal';
Entity bar => sub {'baz'};
}]
	     ]);

  isnt $root->get_widget_from_dir
    ($root, qw(index)), undef, "[$SESSION] index reload";
}

# [6] Reload should not occur during initialization.
SKIP: {
  #
  # TEST_NO_RELOAD_DIR=app:lib1/normal
  #
  $SESSION++;
  my $builder = $TMPDIR->as_sub;
  my $DIR = $builder->
    ([DIR => 'app'
      , [FILE => '.htyattrc'
	 , q{ BEGIN {::main::wait_and_touch('app')}
	     ;use YATT::Registry base => '/normal'; sub foo {"FOO"}}]
      , [FILE => 'index.html', q{<h2>foo</h2>}]],
     [DIR => 'lib1'
      , [DIR => 'normal'
	 , [FILE => '.htyattrc'
	    , q{BEGIN {::main::wait_and_touch('lib1/normal')}
		;use YATT::Registry base => '/common'; sub bar {"BAR"}}]
	 , [FILE => 'bar.html', q{<h2>bar<!yatt:baz></h2>}]]
      , [DIR => 'common'
	 , [FILE => '.htyattrc'
	    , q{sub baz {"BAZ"}}]]]);

  use File::stat;
  my %no_reload; $no_reload{$_} = 1 for split ":"
    , ($ENV{TEST_NO_RELOAD_DIR} || '');
  my %prevDepth;
  sub touch {
    my ($fn) = @_;
    my $time = time;
    utime undef, undef, $fn
  }
  sub wait_and_touch {
    my ($key) = @_;
    return if $no_reload{$key};
    my $curDepth = call_depth();
    if (defined $prevDepth{$key}) {
      # dir 修正は一度だけ。
      return;
    }
    $prevDepth{$key} = $curDepth;

    my $fn = "$DIR/$key";
    my $old = stat($fn)->mtime;
    my $before = Time::HiRes::time;
    print STDERR "# before check, now=$before\n"
      if $ENV{VERBOSE};
    if (my $slept = wait_for_time($old + 1)) {
      print STDERR "# slept $slept sec for $fn\n" if $ENV{VERBOSE};
    }
    ok touch($fn), "touch $fn";
    if (stat($fn)->mtime == $old) {
      # XXX: In rare case(I think), touch failed.
      my $max_retry = default($ENV{RETRY}, 3);
      my $retry = 0;
      while (stat($fn)->mtime == $old and $retry < $max_retry) {
	sleep 1;
	ok touch($fn), "touch $fn retry $retry";
      } continue { $retry++ }
      my $now = Time::HiRes::time;
      my $diff = ($old + 1) - $now;
      isnt stat($fn)->mtime, $old
	, "[$SESSION] mtime should be changed $fn after $retry retries"
	  . " (now=$now, diff=$diff).";
    }
    print STDERR "#caller: ", call_depth(), "\n" if $ENV{VERBOSE};
  }

  sub call_depth {
    my $depth = 0;
    $depth++ while caller($depth);
    $depth;
  }

  my $root = new YATT::Registry
    (loader => [DIR => "$DIR/app", LIB => "$DIR/lib1"]
     , app_prefix => "MyApp$SESSION"
     , auto_reload => 1);
  is_deeply [sort $root->list_ns], [qw(common index normal)]
    , "[$SESSION] base => /normal";

  isnt my $index = $root->get_ns(['index']), undef, "[$SESSION] index";
  my $w;
  like(catch {$w = $root->get_widget_from_template($index, qw(yatt bar))}
       , qr{^\QUnknown declarator (<!yatt:baz >)}, "[$SESSION] bar");

  is $root->get_ns(['bar'])->{is_loaded}
    , undef, "[$SESSION] yatt bar is not yet loaded";

  wait_and_touch("lib1/normal/bar.html");

  # Now we have correct bar.
  $builder->
    ([DIR => 'lib1'
      , [DIR => 'normal'
	 , [FILE => 'bar.html'
	    , (my $new_bar = q{<h2>bar<yatt:baz /></h2>})
	    . q{<!yatt:widget baz>baz}]]]);

  $root->mark_load_failure;

  undef $w;
  like(catch {$w = $root->get_widget_from_template($index, qw(yatt bar))}
       , qr{^$}, "[$SESSION] bar, reload, noerror");

  is $root->get_ns(['bar'])->{is_loaded}
    , 1, "[$SESSION] yatt bar *is* loaded";

  eq_or_diff stringify_node($w->root)
    , $new_bar, "[$SESSION] bar, reloaded";
}
