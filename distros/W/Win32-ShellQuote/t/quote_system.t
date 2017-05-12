use strict;
use warnings FATAL => 'all';
use Test::More $^O eq 'MSWin32' ? ()
  : (skip_all => "can only test system calls on Win32");

use File::Basename qw(dirname);
use File::Spec::Functions qw(catfile catdir rel2abs);
use Win32::ShellQuote qw(:all);
use File::Temp qw(tempdir);
use File::Copy qw(copy);
use Cwd ();
use lib 't/lib';
use TestUtil;

my $tlib = rel2abs('t/lib');
my $dumper_orig = rel2abs(catfile(dirname(__FILE__), 'dump_args.pl'));

my $cwd = Cwd::cwd;
my $guard = guard { chdir $cwd };

my $tmpdir = tempdir CLEANUP => 1;
chdir $tmpdir;

my $test_dir = catdir $tmpdir, "dir with spaces";
mkdir $test_dir;

my $test_dumper = catfile $test_dir, 'dumper with spaces.pl';
copy $dumper_orig, $test_dumper;

for my $dump (
  [1, $^X, "-I$tlib", $dumper_orig],
  [1, $^X, "-I$tlib", $test_dumper],
  [0, 'IF', 'NOT', 'foo==bar', $^X, "-I$tlib", $dumper_orig],
) {
  my ($pass, @dump) = @$dump;
  my $cmp = $pass ? 'eq' : 'ne';
  my $params = [ '"a" "b"' ];
  my $name = 'roundtrip '
    . ((grep m/ /, @dump) ? 'with spaces ' : '')
    . ($pass ? 'succeeds' : 'with bad perl path fails');

  cmp_ok +capture { system quote_system_list(@dump, @$params) }, $cmp, dd $params,
    "list $name";
  cmp_ok +capture { system quote_system_string(@dump, @$params) }, $cmp, dd $params,
    "string $name";
  cmp_ok +capture { system quote_system_cmd(@dump, @$params) }, $cmp, dd $params,
    "cmd $name";
}

my @dump = ($^X, "-I$tlib", $dumper_orig);
for my $params (
  [ '"a" "b"'           ],
  [ '"a" "b"', '>out'   ],
  [ '"a" "b"', '%PATH%' ],
  [ '"a" ^"b"'          ],
  [ qq["a"\n"b"]        ],
  [ qq["a"| "b\n"]      ],
  [ qq[ \n " < ]        ],
  ( $ENV{AUTHOR_TESTING}
    ? map [ make_random_strings( 1 + int rand 3 ) ], 1 .. 20
    : ()
  ),
) {
  my $name = dd($params);
  eval {
    my $out = capture { system quote_system_list(@dump, @$params) };
    is $out, dd $params, "$name as list";
  };
  if (my $e = $@) {
    fail "$name as list";
    chomp $e;
    diag $e;
  }

  {
    local $TODO = 'forced to use cmd, but using non-escapable characters'
      if Win32::ShellQuote::_has_shell_metachars(quote_native(@$params))
        && grep { /[\r\n\0]/ } @$params;

    eval {
      my $out = capture { system quote_system_string(@dump, @$params) };
      is $out, dd $params, "$name as string";
    };
    if (my $e = $@) {
      fail "$name as string";
      chomp $e;
      diag $e;
    }
  }

  {
    local $TODO = "newlines don't play well with cmd"
      if grep { /[\r\n\0]/ } @$params;
    eval {
      my $out = capture { system quote_system_cmd(@dump, @$params) };
      is $out, dd $params, "$name as cmd";
    };
    if (my $e = $@) {
      fail "$name as cmd";
      chomp $e;
      diag $e;
    }
  }
}

done_testing;
