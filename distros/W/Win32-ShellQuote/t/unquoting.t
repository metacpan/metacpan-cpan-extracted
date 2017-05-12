use strict;
use warnings FATAL => 'all';
use Test::More;

use File::Basename qw(dirname);
use File::Spec::Functions qw(catfile catdir);
use Win32::ShellQuote qw(unquote_native quote_system_string);
use lib 't/lib';
use TestUtil;

my $dump;

for my $strings (
  [ ''                     => [                 ] ],
  [ 'a" "b\\c" "d'         => [ 'a b\c d'       ] ],
  [ 'a" "b\\c" "d   '      => [ 'a b\c d'       ] ],
  [ '"a b\\c d"'           => [ 'a b\c d'       ] ],
  [ '"a b"\\"c d"'         => [ 'a b"c', 'd'    ] ],
  [ '"a b"\\\\"c d"'       => [ 'a b\c d'       ] ],
  [ '"a"\\"b" "a\\"b"'     => [ 'a"b a"b'       ] ],
  [ '"a"\\\\"b" "a\\\\"b"' => [ 'a\b', 'a\b'    ] ],
  [ '"a"\\"b a\\"b"'       => [ 'a"b', 'a"b'    ] ],
  [ 'a"\\"b" "a\\"b'       => [ 'a"b', 'a"b'    ] ],
  [ 'a"\\"b"  "a\\"b'      => [ 'a"b', 'a"b'    ] ],
  [ 'a           b'        => [ 'a', 'b'        ] ],
  [ 'a           b    '    => [ 'a', 'b'        ] ],
  [ "a\nb"                 => [ 'a', 'b'        ] ],
  [ 'a"\\"b a\\"b'         => [ 'a"b a"b'       ] ],
  [ '"a""b" "a"b"'         => [ 'a"b ab'        ] ],
  [ '\\"a\\"'              => [ '"a"'           ] ],
  [ '"a"" "b"'             => [ 'a"', 'b'       ] ],
  [ 'a"b'                  => [ 'ab'            ] ],
  [ 'a""b'                 => [ 'ab'            ] ],
  [ 'a"""b'                => [ 'a"b'           ] ],
  [ 'a""""b'               => [ 'a"b'           ] ],
  [ 'a"""""b'              => [ 'a"b'           ] ],
  [ 'a""""""b'             => [ 'a""b'          ] ],
  [ '"a"b"'                => [ 'ab'            ] ],
  [ '"a""b"'               => [ 'a"b'           ] ],
  [ '"a"""b"'              => [ 'a"b'           ] ],
  [ '"a""""b"'             => [ 'a"b'           ] ],
  [ '"a"""""b"'            => [ 'a""b'          ] ],
  [ '"a""""""b"'           => [ 'a""b'          ] ],
  [ ''                     => [                 ] ],
  [ ' '                    => [                 ] ],
  [ '""'                   => [ ''              ] ],
  [ '" "'                  => [ ' '             ] ],
  [ '""a'                  => [ 'a'             ] ],
  [ '""a b'                => [ 'a', 'b'        ] ],
  [ 'a""'                  => [ 'a'             ] ],
  [ 'a"" b'                => [ 'a', 'b'        ] ],
  [ '"" a'                 => [ '', 'a'         ] ],
  [ 'a ""'                 => [ 'a', ''         ] ],
  [ 'a "" b'               => [ 'a', '', 'b'    ] ],
  [ 'a " " b'              => [ 'a', ' ', 'b'   ] ],
  [ 'a " b " c'            => [ 'a', ' b ', 'c' ] ],
  [ 'a "0" c'              => [ 'a', '0', 'c'   ] ],
  [ '"a\\b"'               => [ 'a\\b'          ] ],
  [ '"a\\\\b"'             => [ 'a\\\\b'        ] ],
  [ '"a\\\\\\b"'           => [ 'a\\\\\\b'      ] ],
  [ '"a\\\\\\\\b"'         => [ 'a\\\\\\\\b'    ] ],
  [ '"a\\"'                => [ 'a"'            ] ],
  [ '"a\\\\"'              => [ 'a\\'           ] ],
  [ '"a\\\\\\"'            => [ 'a\\"'          ] ],
  [ '"a\\\\\\\\"'          => [ 'a\\\\'         ] ],
  [ '"a\\\\\\""'           => [ 'a\\"'          ] ],
) {
  my ($string, $args) = @$strings;
  my $name = $string;
  s/\r/\\r/, s/\n/\\n/ for $name;
  my $want = dd $args;
  my $got = dd [ unquote_native($string) ];
  is $got, $want, "[$name] unquoted as expected";
  if ($^O eq 'MSWin32' && $ENV{AUTHOR_TESTING}) {
    $dump ||= quote_system_string($^X, "-It/lib", catfile(dirname(__FILE__), 'dump_args.pl'));
    my $real = capture { system "$dump $string" };
    is $want, $real, "[$name] test data is correct";
    is $got, $real, "[$name] unquoted as real";
  }
}

done_testing;
