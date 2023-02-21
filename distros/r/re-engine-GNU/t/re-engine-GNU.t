use strict;
use warnings FATAL => 'all';
use IO::Handle;

use Test::More tests => 60;
use Test::More::UTF8;

BEGIN {
    require_ok('re::engine::GNU')
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
#
# Syntax convenient flags
#
ok (0x00be0cd == $re::engine::GNU::RE_SYNTAX_AWK, 'RE_SYNTAX_AWK');
ok (0x10102c6 == $re::engine::GNU::RE_SYNTAX_ED, 'RE_SYNTAX_ED');
ok (0x000a91c == $re::engine::GNU::RE_SYNTAX_EGREP, 'RE_SYNTAX_EGREP');
ok (0x0000000 == $re::engine::GNU::RE_SYNTAX_EMACS, 'RE_SYNTAX_EMACS');
ok (0x023b24d == $re::engine::GNU::RE_SYNTAX_GNU_AWK, 'RE_SYNTAX_GNU_AWK');
ok (0x0000b06 == $re::engine::GNU::RE_SYNTAX_GREP, 'RE_SYNTAX_GREP');
ok (0x02bb2fd == $re::engine::GNU::RE_SYNTAX_POSIX_AWK, 'RE_SYNTAX_POSIX_AWK');
ok (0x10102c6 == $re::engine::GNU::RE_SYNTAX_POSIX_BASIC, 'RE_SYNTAX_POSIX_BASIC');
ok (0x020bb1c == $re::engine::GNU::RE_SYNTAX_POSIX_EGREP, 'RE_SYNTAX_POSIX_EGREP');
ok (0x003b2fc == $re::engine::GNU::RE_SYNTAX_POSIX_EXTENDED, 'RE_SYNTAX_POSIX_EXTENDED');
ok (0x00106c4 == $re::engine::GNU::RE_SYNTAX_POSIX_MINIMAL_BASIC, 'RE_SYNTAX_POSIX_MINIMAL_BASIC');
ok (0x003f2ec == $re::engine::GNU::RE_SYNTAX_POSIX_MINIMAL_EXTENDED, 'RE_SYNTAX_POSIX_MINIMAL_EXTENDED');
ok (0x10102c6 == $re::engine::GNU::RE_SYNTAX_SED, 'RE_SYNTAX_SED');
#
# Internal flags
#
ok (defined($re::engine::GNU::RE_BACKSLASH_ESCAPE_IN_LISTS), 'RE_BACKSLASH_ESCAPE_IN_LISTS');
ok (defined($re::engine::GNU::RE_BK_PLUS_QM), 'RE_BK_PLUS_QM');
ok (defined($re::engine::GNU::RE_CHAR_CLASSES), 'RE_CHAR_CLASSES');
ok (defined($re::engine::GNU::RE_CONTEXT_INDEP_ANCHORS), 'RE_CONTEXT_INDEP_ANCHORS');
ok (defined($re::engine::GNU::RE_CONTEXT_INDEP_OPS), 'RE_CONTEXT_INDEP_OPS');
ok (defined($re::engine::GNU::RE_CONTEXT_INVALID_OPS), 'RE_CONTEXT_INVALID_OPS');
ok (defined($re::engine::GNU::RE_DOT_NEWLINE), 'RE_DOT_NEWLINE');
ok (defined($re::engine::GNU::RE_DOT_NOT_NULL), 'RE_DOT_NOT_NULL');
ok (defined($re::engine::GNU::RE_HAT_LISTS_NOT_NEWLINE), 'RE_HAT_LISTS_NOT_NEWLINE');
ok (defined($re::engine::GNU::RE_INTERVALS), 'RE_INTERVALS');
ok (defined($re::engine::GNU::RE_LIMITED_OPS), 'RE_LIMITED_OPS');
ok (defined($re::engine::GNU::RE_NEWLINE_ALT), 'RE_NEWLINE_ALT');
ok (defined($re::engine::GNU::RE_NO_BK_BRACES), 'RE_NO_BK_BRACES');
ok (defined($re::engine::GNU::RE_NO_BK_PARENS), 'RE_NO_BK_PARENS');
ok (defined($re::engine::GNU::RE_NO_BK_REFS), 'RE_NO_BK_REFS');
ok (defined($re::engine::GNU::RE_NO_BK_VBAR), 'RE_NO_BK_VBAR');
ok (defined($re::engine::GNU::RE_NO_EMPTY_RANGES), 'RE_NO_EMPTY_RANGES');
ok (defined($re::engine::GNU::RE_UNMATCHED_RIGHT_PAREN_ORD), 'RE_UNMATCHED_RIGHT_PAREN_ORD');
ok (defined($re::engine::GNU::RE_NO_POSIX_BACKTRACKING), 'RE_NO_POSIX_BACKTRACKING');
ok (defined($re::engine::GNU::RE_NO_GNU_OPS), 'RE_NO_GNU_OPS');
ok (defined($re::engine::GNU::RE_DEBUG), 'RE_DEBUG');
ok (defined($re::engine::GNU::RE_INVALID_INTERVAL_ORD), 'RE_INVALID_INTERVAL_ORD');
ok (defined($re::engine::GNU::RE_ICASE), 'RE_ICASE');
ok (defined($re::engine::GNU::RE_CARET_ANCHORS_HERE), 'RE_CARET_ANCHORS_HERE');
ok (defined($re::engine::GNU::RE_CONTEXT_INVALID_DUP), 'RE_CONTEXT_INVALID_DUP');
ok (defined($re::engine::GNU::RE_NO_SUB), 'RE_NO_SUB');
my ($t1, $t2, $t3, $t4, $t5);
{
  use re::engine::GNU -debug => $ENV{AUTHOR_TEST} || 0;
  $t1 = 'test' =~ qr/\(tes\)t/;
  no re::engine::GNU;
}
ok ($t1, "'test' =~ qr/\\(tes\\)t/");
{
  use re::engine::GNU -debug => $ENV{AUTHOR_TEST} || 0;
  $t2 = 'test' =~ [ 0, '\(tes\)t' ];
  no re::engine::GNU;
}
ok ($t2, "'test' =~ [ 0, '\\(tes\\)t' ]");
{
  use re::engine::GNU -debug => $ENV{AUTHOR_TEST} || 0;
  $t3 = 'test' =~ { syntax => 0, pattern => '\(tes\)t' };
  no re::engine::GNU;
}
ok ($t3, "'test' =~ { syntax => 0, pattern => '\\(tes\\)t' }");
{
  use re::engine::GNU -debug => $ENV{AUTHOR_TEST} || 0;
  #
  # Gnulib own test
  #
  my $r4 = { syntax =>
             $re::engine::GNU::RE_SYNTAX_GREP |
             $re::engine::GNU::RE_HAT_LISTS_NOT_NEWLINE |
             $re::engine::GNU::RE_ICASE,
             pattern => "insert into"};
  $t4 = "\x{FF}\0\x{12}\x{A2}\x{AA}\x{C4}\x{B1},K\x{12}\x{C4}\x{B1}*\x{AC}K" !~ $r4;
  no re::engine::GNU;
}
ok ($t4, "http://sourceware.org/ml/libc-hacker/2006-09/msg00008.html");
{
  use re::engine::GNU -debug => $ENV{AUTHOR_TEST} || 0;
  #
  # UTF-8
  #
  # PV = 0x99be7e8 "\341\200\200   0.. 2
  #                 \341\200\273   3.. 5
  #                 \341\200\275   6.. 8
  #                 \341\200\224   9..11
  #                 \341\200\272  12..14
  #                 \341\200\257  15..17
  #                 \341\200\225  18..20
  #                 \341\200\272  21..23
  #                 x             24
  #                 y             25
  #                 "\0 [UTF8 "\x{1000}\x{103b}\x{103d}\x{1014}\x{103a}\x{102f}\x{1015}\x{103a}xy"]

  $t5 = "\x{1000}\x{103B}\x{103D}\x{1014}\x{103A}\x{102F}\x{1015}\x{103A}xy" =~ qr/\([^x]\)\(x\)/p;
  is ($1, "\x{103A}", "utf8 \$1");
  is ($2, "x", "utf8 \$2");
  is ($-[0], 7, "utf8 \$-[0]");
  is ($+[0], 9, "utf8 \$-[0]");
  is ($-[1], 7, "utf8 \$-[1]");
  is ($+[1], 8, "utf8 \$-[1]");
  is ($-[2], 8, "utf8 \$-[2]");
  is ($+[2], 9, "utf8 \$-[2]");
  is (${^PREMATCH}, "\x{1000}\x{103B}\x{103D}\x{1014}\x{103A}\x{102F}\x{1015}", "utf8 \${^PREMATCH}");
  is (${^MATCH}, "\x{103A}x", "utf8 \${^MATCH}");
  is (${^POSTMATCH}, "y", "utf8 \${^POSTMATCH}");
  is ($`, "\x{1000}\x{103B}\x{103D}\x{1014}\x{103A}\x{102F}\x{1015}", "utf8 \$\`");
  is ($&, "\x{103A}x", "utf8 \$&");
  is ($', "y", "utf8 \$'");
  no re::engine::GNU;
}
ok ($t5, "\"\\x{1000}\\x{103B}\\x{103D}\\x{1014}\\x{103A}\\x{102F}\\x{1015}\\x{103A}xy\" =~ qr/\\([^x]\\)\\(x\\)/p");
{
  use re::engine::GNU -debug => $ENV{AUTHOR_TEST} || 0;
  my @matches = ();
  while ("\x{1000}\x{103B}\x{103D}\x{1014}\x{103A}\x{102F}\x{1015}\x{103A}x" =~ m/\([^x]\)/g) {
    push(@matches, $1);
  }
  is_deeply(\@matches, [ "\x{1000}", "\x{103B}", "\x{103D}", "\x{1014}", "\x{103A}", "\x{102F}", "\x{1015}", "\x{103A}" ], 'utf8 m//g');
  no re::engine::GNU;
}

1;
