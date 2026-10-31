#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use List::Util qw(sum);
# use encoding qw(:locale);
use utf8;
# use open qw(:locale);
BEGIN {
  require encoding;
  my $locale = encoding::_get_locale_encoding() || 'utf-8';
  my $enc = encoding::find_encoding($locale);
  my $encName = $enc->name;
  foreach my $fh (\*STDERR, \*STDOUT, \*STDIN) {
    binmode $fh, ":raw :encoding($encName)";
  }
}

use Encode;

use YATT::Lite::Test::TestUtil;
#========================================
use YATT::t::t_preload; # To make Devel::Cover happy.

use YATT::Lite qw/*CON/;
use YATT::Lite::Util qw/
                         lexpand
                         appname
                         is_done
                         terse_dump
                     /;

# Several fixtures print references (lists, hashes) through escape(),
# which dumps them only when HTDEBUG_DUMP is on (or in development).
$ENV{HTDEBUG_DUMP} = 1;
sub myapp {join _ => MyTest => appname($0), @_}

use YATT::Lite::Breakpoint;

use YATT::Lite::Test::XHFTest qw(Item);
use parent qw(YATT::Lite::Test::XHFTest File::Spec);
use YATT::Lite::MFields qw(VFS_CONFIG YATT_CONFIG YATT_RC
			   ONLY_UTF8
			);

my @files = MY->list_files(@ARGV ? @ARGV
			   : <$FindBin::Bin/xhf/*/*.xhf>);

my (@section);
foreach my $fn (@files) {
  eval {
    push @section, my MY $sect = MY->load(file => untaint_any($fn));
    if (my $cf = $sect->{YATT_CONFIG} and my $enc = $sect->{encoding}) {
      $sect->convert_enc_array($enc, $cf);
    }
  };
  die "Error while loading $fn: $@" if $@;
}

my ($test_lang) = grep {defined $ENV{$_}} qw/LC_ALL LANG/;
my $skip_test_lang = !$test_lang || ($ENV{$test_lang} !~ /\.UTF-?8$/i);

my $ntests = (@section * 2) + sum(map {$_->ntests} @section);
plan tests => $ntests + ($skip_test_lang ? 0 : 1);

if (not $skip_test_lang) {
  my $got = captured(undef, sub {
		       my ($this, $fh) = @_;
		       # 世界！
		       print $fh "\x{4e16}\x{754c}\x{ff01}";
		     });
  $skip_test_lang = $got ne "\xe4\xb8\x96\xe7\x95\x8c\xef\xbc\x81";
  ok !$skip_test_lang, "Sanity check for captured. $test_lang=$ENV{$test_lang}.";
}

my $i = 1;
foreach my MY $sect (@section) {
  my $skip_no_utf8 = $sect->{ONLY_UTF8} && $skip_test_lang;

  my $fn = path_tail($sect->{filename}, 2);
  # XXX: as_vfs_spec => data => {}, rc => '...';
  my $spec = [data => $sect->as_vfs_data];
  if (my $cf = $sect->{VFS_CONFIG}) {
    push @$spec, @$cf;
  }
  ok(my $yatt = new YATT::Lite(app_ns => myapp($i)
			       , vfs => $spec
			       , debug_cgen => $ENV{DEBUG}
			       , debug_parser => 0
			       , lexpand($sect->{YATT_CONFIG})
			       , $sect->{YATT_RC}
			       ? (rc_script => $sect->{YATT_RC}) : ()
			      )
     , "$fn new YATT::Lite");
  is ref $yatt, 'YATT::Lite', 'new YATT::Lite package';
  local $YATT::Lite::YATT = $yatt; # XXX: runyatt に切り替えられないか？
  my $last_title;
  TODO:
  foreach my Item $test (@{$sect->{_tests}}) {
    next unless $test->is_runnable;
    my $title = "[$fn] " . ($test->{TITLE} // $last_title
			    // $test->{ERROR} // "(undef)");
    $title .= " ($test->{_num})" if $test->{_num};
    local $TODO = $test->{TODO};
  SKIP: {
      if (($test->{SKIP} or $test->{PERL_MINVER} or $skip_no_utf8)
	  and my $skip = $test->ntests) {
	if ($test->{PERL_MINVER} and $] < $test->{PERL_MINVER}) {
	  skip "by perl-$] < PERL_MINVER($test->{PERL_MINVER}) $title", $skip
	} elsif ($test->{SKIP}) {
	  skip "by SKIP: $title", $skip;
	} elsif ($skip_no_utf8) {
	  if ($test_lang) {
	    skip "by $test_lang=$ENV{$test_lang}, which is not UTF8", $skip;
	  } else {
	    skip "by empty LC_ALL/LANG", $skip;
	  }
	}
      }
      if ($test->{REQUIRE}
	  and my @missing = $test->test_require($test->{REQUIRE})) {
	skip "Module @missing is not installed", $test->ntests;
      }
      if ($test->{BREAK}) {
        $DB::single = 1; 1 if $DB::single;
      }
      if ($test->{OUT}) {
	unless ($test->{_realfile}) {
	  die "test realfile is undef!";
	}
	my ($pkg, $compile_error) = do {
          my $error;
          local $SIG{__DIE__} = sub {$error = @_ > 1 ? [@_] : shift};
          local $SIG{__WARN__} = sub {$error = @_ > 1 ? [@_] : shift};
          my $pkg = eval {
            my $tmpl = $yatt->find_file($test->{_realfile});

            #
            # Workaround for false failure caused by Devel::Cover.
            #
            local $SIG{__WARN__} = sub {
              my ($msg) = @_;
              return if $msg =~ /^Devel::Cover: Can't open \S+ for MD5 digest:/;
              die $msg;
            };

            $yatt->find_product(perl => $tmpl);
          };

          is $error, undef, "$title - compiled.";

          ($pkg, $error);
        };
	if ($compile_error) {
	  skip "not compiled - $title", 1;
	} else {
          my $error;
          local $SIG{__DIE__} = sub {$error = @_ > 1 ? [@_] : shift};
          local $SIG{__WARN__} = sub {$error = @_ > 1 ? [@_] : shift};

          my $buffer = "";
	  eval {
            {
              local $CON = do {
                if (my $class = $test->{CON_CLASS}) {
                  YATT::Lite::Util::ckrequire($class);
                  $class->create(
                    undef,
                    noheader => 1,
                    buffer => \ $buffer,
                    parameters => YATT::Lite::Util::ixhash(lexpand($test->{PARAM})),
                  );
                } else {
                  open my $fh, '>:utf8', \ $buffer;
                  $fh;
                }
              };
              $pkg->render_($CON, lexpand($test->{PARAM}));
            }
	  };

          if ($error and not is_done($error)) {
	    fail "$title: runtime error: ".terse_dump($error);
          } else {
            eq_or_diff $buffer, encode(utf8 => $test->{OUT}), "$title";
	  }
	}
      } elsif ($test->{ERROR} or $test->{ERROR_BODY}) {
	eval {
	  my $tmpl = $yatt->find_file($test->{_realfile});
	  my $pkg = $yatt->find_product(perl => $tmpl);
	  captured($pkg => render_ => lexpand($test->{PARAM}));
	};
        if (ref $test->{ERROR_BODY}) {
          is_deeply $@->[2], $test->{ERROR_BODY}, $title;
        } elsif (ref $test->{ERROR}) {
          is_deeply $@, $test->{ERROR}, $title;
        } else {
          like $@, qr{^$test->{ERROR}}, $title;
        }
      }
    }
    $last_title = $test->{TITLE} if $test->{TITLE};
  }
} continue { $i++ }

sub captured {
  my ($obj, $method, @args) = @_;
  open my $fh, ">", \ (my $buf = "") or die $!;
  binmode $fh, ":encoding(utf8)"; #XXX: 常に、で大丈夫なのか?
  # XXX: locale と一致しなかったらどうすんの?
  if (ref $method) {
    $method->($obj, $fh, @args);
  } else {
    $obj->$method($fh, @args);
  }
  close $fh;
  $buf;
}

sub path_tail {
  my $fn = shift;
  my $len = shift // 1;
  my @path = MY->splitdir($fn);
  splice @path, 0, @path - $len;
  wantarray ? @path : MY->catdir(@path);
}

done_testing();
