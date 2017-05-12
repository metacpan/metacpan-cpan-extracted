# -*- mode: perl; coding: utf-8 -*-
package YATT::Test;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use base qw(Test::More);
BEGIN {$INC{'YATT/Test.pm'} = __FILE__}

use File::Basename;
use Cwd;

use Data::Dumper;
use Carp;

use Time::HiRes qw(usleep);

use YATT;
use YATT::Util qw(rootname catch checked_eval default defined_fmt
		  require_and
		);
use YATT::Util::Symbol;
use YATT::Util::Finalizer;
use YATT::Util::DirTreeBuilder qw(tmpbuilder);
use YATT::Util::DictOrder;

#========================================

our @EXPORT = qw(ok is isnt like is_deeply skip fail plan
		 require_ok isa_ok
		 basename

		 wait_for_time

		 is_rendered raises is_can run
		 capture rootname checked_eval default defined_fmt
		 tmpbuilder
		 dumper

		 xhf_test
		 *TRANS
	       );
foreach my $name (@EXPORT) {
  my $glob = globref(__PACKAGE__, $name);
  unless (*{$glob}{CODE}) {
    *$glob = \&{globref("Test::More", $name)};
  }
}

*eq_or_diff = do {
  if (catch {require Test::Differences} \ my $error) {
    \&Test::More::is;
  } else {
    \&Test::Differences::eq_or_diff;
  }
};

push @EXPORT, qw(eq_or_diff);

our @EXPORT_OK = @EXPORT;

#========================================

sub run {
  my ($testname, $sub) = @_;
  my $res = eval { $sub->() };
  Test::More::is $@, '', "$testname doesn't raise error";
  $res
}

sub is_can ($$$) {
  my ($desc, $cmp, $title) = @_;
  my ($obj, $method, @args) = @$desc;
  my $sub = $obj->can($method);
  Test::More::ok defined $sub, "$title - can";
  if ($sub) {
    Test::More::is scalar($sub->($obj, @args)), $cmp, $title;
  } else {
    Test::More::fail "skipped because method '$method' not found.";
  }
}

sub is_rendered ($$$) {
  my ($desc, $cmp, $title) = @_;
  my ($trans, $path, @args) = @$desc;
  my $error;
  local $SIG{__DIE__} = sub {$error = @_ > 1 ? [@_] : shift};
  local $SIG{__WARN__} = sub {$error = @_ > 1 ? [@_] : shift};
  my ($sub, $pkg) = eval {
    &YATT::break_translator;
    $trans->get_handler_to(render => @$path)
  };
  Test::More::is $error, undef, "$title - compiled.";
  eval {
    if ($sub) {
      my $out = capture {
	&YATT::break_handler;
	$sub->($pkg, @args);
      };
      $out =~ s{\r}{}g if defined $out;
      eq_or_diff($out, $cmp, $title);
    } elsif ($error) {
      Test::More::fail "skipped, because of previous compile error for [$title]: $error";
    }
  };
  if ($@) {
    Test::More::fail "$title: runtime error: $@";
  }
}

sub raises ($$$) {
  my ($desc, $cmp, $title) = @_;
  my ($trans, $method, @args) = @$desc;
  my $result = eval {capture {$trans->$method(@args)}};
  Test::More::like $@, $cmp, $title;
  $result;
}

#----------------------------------------

sub dumper {
  join "\n", map {
    Data::Dumper->new([$_])->Terse(1)->Indent(0)->Dump;
  } @_;
}

#----------------------------------------
use base qw(YATT::Class::Configurable);
use YATT::Types -base => __PACKAGE__
  , [TestDesc => [qw(cf_FILE realfile
		     ntests
		     cf_TITLE num cf_TAG
		     cf_BREAK
		     cf_SKIP
		     cf_WIDGET
		     cf_RANDOM
		     cf_IN cf_PARAM cf_OUT cf_ERROR)]]
  , [Config => [['^cf_translator' => 'YATT::Translator::Perl']
		, '^cf_toplevel'
		, '^TMPDIR', 'gen'
	       ]]
  , [Toplevel => []]
  ;

Config->define(target => sub { my $self = shift; $self->toplevel
				 || $self->translator });

Config->define(new_translator => sub {
  ;#
  (my Config $global, my ($loader, @opts)) = @_;
  require_and($global->translator => new => loader => $loader, @opts);
});

Config->define(configure_DIR => sub {
  ;#
  (my Config $global, my ($dir)) = @_;
  $global->{TMPDIR} = tmpbuilder($dir);
});

sub ntests {
  my $ntests = 0;
  foreach my $section (@_) {
    foreach my TestDesc $test (@{$section}[1 .. $#$section]) {
      $ntests += $test->{ntests};
    }
  }
  $ntests;
}

sub xhf_test {
  my Config $global = do {
    shift->Config->new(DIR => shift);
  };

  if (@_ == 1 and -d $_[0]) {
    my $srcdir = shift;
    @_ = dict_sort <$srcdir/*.xhf>;
  }

  croak "Source is missing." unless @_;
  my @sections = $global->xhf_load_sections(@_);

  Test::More::plan(tests => 1 + ntests(@sections));

  require_ok($global->target);

  $global->xhf_do_sections(@sections);
}

sub xhf_load_sections {
  my Config $global = shift;

  require YATT::XHF;

  my @sections;
  foreach my $testfile (@_) {
    my $parser = new YATT::XHF(filename => $testfile);
    my TestDesc $prev;
    my ($n, @test, %uniq) = (0);
    while (my $rec = $parser->read_as_hash) {
      if ($rec->{global}) {
	$global->configure(%{$rec->{global}});
	next;
      }
      push @test, my TestDesc $test = $global->TestDesc->new(%$rec);
      $test->{ntests} = $global->ntests_in_desc($test);
      $test->{cf_FILE} ||= $prev && $prev->{cf_FILE}
	&& $prev->{cf_FILE} =~ m{%d} ? $prev->{cf_FILE} : undef;

      if ($test->{cf_IN}) {
	use YATT::Util::redundant_sprintf;
	$test->{realfile} = sprintf($test->{cf_FILE} ||= "doc/f%d.html", $n);
	$test->{cf_WIDGET} ||= do {
	  my $widget = $test->{realfile};
	  $widget =~ s{^doc/}{};
	  $widget =~ s{\.\w+$}{};
	  $widget =~ s{/}{:}g;
	  $widget;
	};
      }

      if ($test->{cf_OUT}) {
	$test->{cf_WIDGET} ||= $prev && $prev->{cf_WIDGET};
	if (not $test->{cf_TITLE} and $prev) {
	  $test->{num} = default($prev->{num}) + 1;
	  $test->{cf_TITLE} = $prev->{cf_TITLE};
	}
      }
      $prev = $test;
    } continue {
      $n++;
    }

    push @sections, [$testfile => @test];
  }

  @sections;
}

sub xhf_is_runnable {
  (my Config $global, my TestDesc $test) = @_;
  $test->{cf_OUT} || $test->{cf_ERROR};
}

sub xhf_do_sections {
  (my Config $global, my @sections) = @_;

  my $SECTION = 0;
  foreach my $section (@sections) {
    my ($testfile, @all) = @$section;
    my $builder = $global->{TMPDIR}->as_sub;
    my $DIR = $builder->([DIR => "doc"]);

    my @test;
    foreach my TestDesc $test (@all) {
      if ($test->{cf_IN}) {
	die "Conflicting FILE: $test->{realfile}!\n" if -e $test->{realfile};
	$builder->($global->{TMPDIR}->path2desc
		   ($test->{realfile}, $test->{cf_IN}));
      }
      push @test, $test if $global->xhf_is_runnable($test);
    }

    my @loader = (DIR => "$DIR/doc");
    push @loader, LIB => do {
      if (-d "$DIR/lib") {
	my $libdir = "$DIR/lib";
	chmod 0755, $libdir;
	$libdir;
      } else {
	getcwd;
      }
    };

    my %config;
    if (-r (my $fn = "$DIR/doc/.htyattroot")) {
      %config = YATT::XHF->new(filename => $fn)->read_as('pairlist');
    }

    &YATT::break_translator;
    $global->{gen} = ($global->toplevel || $global)->new_translator
      (\@loader
       , app_prefix => "MyApp$SECTION"
       , debug_translator => $ENV{DEBUG}
       , no_lineinfo => YATT::Util::no_lineinfo()
       , %config
      );

    foreach my TestDesc $test (@test) {
      my @widget_path; @widget_path = split /:/, $test->{cf_WIDGET} if $test->{cf_WIDGET};
      my ($param); ($param) = map {ref $_ ? $_ : 'main'->checked_eval($_)}
	$test->{cf_PARAM} if $test->{cf_PARAM};

    SKIP: {
	$global->xhf_runtest_desc($test, $testfile, \@widget_path, $param);
      }
    }
  } continue {
    $SECTION++;
  }
}

sub xhf_runtest_desc {
  (my Config $global, my TestDesc $test
   , my ($testfile, $widget_path, $param)) = @_;

  unless (defined $test->{cf_TITLE}) {
    die "test title is not defined!" . dumper($test);
  }
  my $title = join("", '[', basename($testfile), '] ', $test->{cf_TITLE}
		   , defined_fmt(' (%d)', $test->{num}, ''));

  my $toplevel = $global->toplevel;
  if ($test->{cf_OUT}) {
    Test::More::skip("($test->{cf_SKIP}) $title", 2)
	if $test->{cf_SKIP};

    if ($toplevel
	and my $sub = $toplevel->can("set_random_list")) {
      $sub->($global, $test->{cf_RANDOM});
    }

    &YATT::breakpoint if $test->{cf_BREAK};
    is_rendered [$global->{gen}, $widget_path, $param]
      , $test->{cf_OUT}, $title;
  } elsif ($test->{cf_ERROR}) {
    Test::More::skip("($test->{cf_SKIP}) $title", 1)
	if $test->{cf_SKIP};
    &YATT::breakpoint if $test->{cf_BREAK};
    raises [$global->{gen}, call_handler => render => $widget_path, $param]
      , qr{$test->{cf_ERROR}}s, $title;
  }
}

sub ntests_in_desc {
  (my $this, my TestDesc $test) = @_;
  if ($test->{cf_OUT}) {
    2
  } elsif ($test->{cf_ERROR}) {
    1
  } else {
    0
  }
}

#
sub wait_for_time {
  my ($time) = @_;
  my $now = Time::HiRes::time;
  my $diff = $time - $now;
  return if $diff <= 0;
  usleep(int($diff * 1000 * 1000));
  $diff;
}

1;
