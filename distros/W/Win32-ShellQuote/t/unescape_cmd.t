use strict;
use warnings FATAL => 'all';
use Test::More;

use Win32::ShellQuote qw(cmd_unescape quote_system_string cmd_escape);

use File::Basename qw(dirname);
use File::Spec::Functions qw(catfile);
use lib 't/lib';
use TestUtil;

my $can_get_cmdline;
if (!$ENV{AUTHOR_TESTING}) {
}
elsif ($^O eq 'MSWin32') {
  if (eval { require Win32::API }) {
    $can_get_cmdline = 1;
    note 'using Win32::API to check cmd.exe behavior';
  }
  else {
    note 'need Win32::API to check cmd.exe behavior';
  }
}
else {
  note 'need MSWin32 to check cmd.exe behavior';
}

my $dump;
my $dump_run;

for my $strings (
  [ ''                          => ''                     ],
  [ '\\  "^^ \\"^ ^^ ^\\^\\\\'  => '\\  "^^ \\" ^ \\\\\\' ],
  [ '""\\^ \\^\\^'              => '""\\ \\\\'            ],
  (map [ make_random_string( ['^', '"', '\\', ' '] ) ], 1 .. 10),
) {
  my ($string, $want) = @$strings;
  my $name = $string;
  s/\r/\\r/, s/\n/\\n/ for $name;
  my $got = cmd_unescape $string;
  is $got, $want, "[$name] unquoted as expected"
    if defined $want;
  if ($can_get_cmdline) {
    $dump ||= quote_system_string($^X, catfile(dirname(__FILE__), 'dump_cmdline.pl')) . " --";
    $dump_run ||= '%PATH:~0,0%' . cmd_escape($dump);
    my $real = capture { system "$dump_run $string" };
    is $want, $real, "[$name] test data is correct"
      if defined $want;
    is $got, $real, "[$name] unquoted as real";
  }
}

done_testing;
