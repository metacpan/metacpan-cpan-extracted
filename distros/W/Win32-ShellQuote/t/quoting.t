use strict;
use warnings FATAL => 'all';
use Test::More;

use Win32::ShellQuote qw(:all);
use lib 't/lib';
use TestUtil;

for my $test (
  {
    args    => [ qq[a] ],
    cmd     => qq[^"a^"],
    native  => qq["a"],
    system  => 'native',
  },
  {
    args    => [ qq[a b] ],
    cmd     => qq[^"a b^"],
    native  => qq["a b"],
    system  => 'native',
  },
  {
    args    => [ qq["a b"] ],
    cmd     => qq[^"\\^"a b\\^"^"],
    native  => qq["\\"a b\\""],
    system  => 'native',
  },
  {
    args    => [ qq["a" b] ],
    cmd     => qq[^"\\^"a\\^" b^"],
    native  => qq["\\"a\\" b"],
    system  => 'native',
  },
  {
    args    => [ qq["a" "b"] ],
    cmd     => qq[^"\\^"a\\^" \\^"b\\^"^"],
    native  => qq["\\"a\\" \\"b\\""],
    system  => 'native',
  },
  {
    args    => [ qq['a'] ],
    cmd     => qq[^"'a'^"],
    native  => qq["'a'"],
    system  => 'native',
  },
  {
    args    => [ qq["a] ],
    cmd     => qq[^"\\^"a^"],
    native  => qq["\\"a"],
    system  => 'native',
  },
  {
    args    => [ qq["a b] ],
    cmd     => qq[^"\\^"a b^"],
    native  => qq["\\"a b"],
    system  => 'native',
  },
  {
    args    => [ qq['a] ],
    cmd     => qq[^"'a^"],
    native  => qq["'a"],
    system  => 'native',
  },
  {
    args    => [ qq['a b] ],
    cmd     => qq[^"'a b^"],
    native  => qq["'a b"],
    system  => 'native',
  },
  {
    args    => [ qq['a b"] ],
    cmd     => qq[^"'a b\\^"^"],
    native  => qq["'a b\\""],
    system  => 'native',
  },
  {
    args    => [ qq[\\a] ],
    cmd     => qq[^"\\a^"],
    native  => qq["\\a"],
    system  => 'native',
  },
  {
    args    => [ qq[\\"a] ],
    cmd     => qq[^"\\\\\\^"a^"],
    native  => qq["\\\\\\"a"],
    system  => 'native',
  },
  {
    args    => [ qq[\\ a] ],
    cmd     => qq[^"\\ a^"],
    native  => qq["\\ a"],
    system  => 'native',
  },
  {
    args    => [ qq[\\ "' a] ],
    cmd     => qq[^"\\ \\^"' a^"],
    native  => qq["\\ \\"' a"],
    system  => 'native',
  },
  {
    args    => [ qq[\\ "' a], qq[>\\] ],
    cmd     => qq[^"\\ \\^"' a^" ^"^>\\\\^"],
    native  => qq["\\ \\"' a" ">\\\\"],
    system  => 'native',
  },
  {
    args    => [ qq[%a%] ],
    cmd     => qq[^"^%a^%^"],
    native  => qq["%a%"],
    system  => 'cmd',
  },
  {
    args    => [ qq[%a b] ],
    cmd     => qq[^"^%a b^"],
    native  => qq["%a b"],
    system  => 'cmd',
  },
  {
    args    => [ qq[\\%a b] ],
    cmd     => qq[^"\\^%a b^"],
    native  => qq["\\%a b"],
    system  => 'cmd',
  },
  {
    args    => [ qq[ & help & ] ],
    cmd     => qq[^" ^& help ^& ^"],
    native  => qq[" & help & "],
    system  => 'native',
  },
  {
    args    => [ qq[ > out] ],
    cmd     => qq[^" ^> out^"],
    native  => qq[" > out"],
    system  => 'native',
  },
  {
    args    => [ qq[ | welp] ],
    cmd     => qq[^" ^| welp^"],
    native  => qq[" | welp"],
    system  => 'native',
  },
  {
    args    => [ qq[" | welp"] ],
    cmd     => qq[^"\\^" ^| welp\\^"^"],
    native  => qq["\\" | welp\\""],
    system  => 'cmd',
  },
  {
    args    => [ qq[\\" | welp] ],
    cmd     => qq[^"\\\\\\^" ^| welp^"],
    native  => qq["\\\\\\" | welp"],
    system  => 'cmd',
  },
  {
    args    => [ qq[] ],
    cmd     => qq[^"^"],
    native  => qq[""],
    system  => 'native',
  },
  {
    args    => [ qq[print "foo'o", ' bar"ar'] ],
    cmd     => qq[^"print \\^"foo'o\\^", ' bar\\^"ar'^"],
    native  => qq["print \\"foo'o\\", ' bar\\"ar'"],
    system  => 'native',
  },
  {
    args    => [ qq[\$PATH = 'foo'; print \$PATH] ],
    cmd     => qq[^"\$PATH = 'foo'; print \$PATH^"],
    native  => qq["\$PATH = 'foo'; print \$PATH"],
    system  => 'native',
  },
  {
    args    => [ qq[print 'foo'] ],
    cmd     => qq[^"print 'foo'^"],
    native  => qq["print 'foo'"],
    system  => 'native',
  },
  {
    args    => [ qq[print " \\" "] ],
    cmd     => qq[^"print \\^" \\\\\\^" \\^"^"],
    native  => qq["print \\" \\\\\\" \\""],
    system  => 'native',
  },
  {
    args    => [ qq[print " < \\" "] ],
    cmd     => qq[^"print \\^" ^< \\\\\\^" \\^"^"],
    native  => qq["print \\" < \\\\\\" \\""],
    system  => 'cmd',
  },
  {
    args    => [ qq[print " \\" < "] ],
    cmd     => qq[^"print \\^" \\\\\\^" ^< \\^"^"],
    native  => qq["print \\" \\\\\\" < \\""],
    system  => 'native',
  },
  {
    args    => [ qq[print " < \\"\\" < \\" < \\" < "] ],
    cmd     => qq[^"print \\^" ^< \\\\\\^"\\\\\\^" ^< \\\\\\^" ^< \\\\\\^" ^< \\^"^"],
    native  => qq["print \\" < \\\\\\"\\\\\\" < \\\\\\" < \\\\\\" < \\""],
    system  => 'cmd',
  },
  {
    args    => [ qq[print " < \\" | \\" < | \\" < \\" < "] ],
    cmd     => qq[^"print \\^" ^< \\\\\\^" ^| \\\\\\^" ^< ^| \\\\\\^" ^< \\\\\\^" ^< \\^"^"],
    native  => qq["print \\" < \\\\\\" | \\\\\\" < | \\\\\\" < \\\\\\" < \\""],
    system  => 'cmd',
  },
  {
    args    => [ qq[print q[ &<>^|()\@ ! ]] ],
    cmd     => qq[^"print q[ ^&^<^>^^^|^(^)\@ ^! ]^"],
    native  => qq["print q[ &<>^|()\@ ! ]"],
    system  => 'native',
  },
  {
    args    => [ qq[print q[ &<>^|\@()!"&<>^|\@()! ]] ],
    cmd     => qq[^"print q[ ^&^<^>^^^|\@^(^)^!\\^"^&^<^>^^^|\@^(^)^! ]^"],
    native  => qq["print q[ &<>^|\@()!\\"&<>^|\@()! ]"],
    system  => 'cmd',
  },
  {
    args    => [ qq[print q[ "&<>^|\@() !"&<>^|\@() !" ]] ],
    cmd     => qq[^"print q[ \\^"^&^<^>^^^|\@^(^) ^!\\^"^&^<^>^^^|\@^(^) ^!\\^" ]^"],
    native  => qq["print q[ \\"&<>^|\@() !\\"&<>^|\@() !\\" ]"],
    system  => 'cmd',
  },
  {
    args    => [ qq[print q[ "C:\\TEST A\\" ]] ],
    cmd     => qq[^"print q[ \\^"C:\\TEST A\\\\\\^" ]^"],
    native  => qq["print q[ \\"C:\\TEST A\\\\\\" ]"],
    system  => 'native',
  },
  {
    args    => [ qq[print q[ "C:\\TEST %&^ A\\" ]] ],
    cmd     => qq[^"print q[ \\^"C:\\TEST ^%^&^^ A\\\\\\^" ]^"],
    native  => qq["print q[ \\"C:\\TEST %&^ A\\\\\\" ]"],
    system  => 'cmd',
  },
  {
    args    => [ qq[\n] ],
    cmd     => undef,
    native  => qq["\n"],
    system  => 'native',
  },
  {
    args    => [ qq[a\nb] ],
    cmd     => undef,
    native  => qq["a\nb"],
    system  => 'native',
  },
  {
    args    => [ qq[a\rb] ],
    cmd     => undef,
    native  => qq["a\rb"],
    system  => 'native',
  },
  {
    args    => [ qq[a\nb > welp] ],
    cmd     => undef,
    native  => qq["a\nb > welp"],
    system  => 'native',
  },
  {
    args    => [ qq[a > welp\n219] ],
    cmd     => undef,
    native  => qq["a > welp\n219"],
    system  => 'native',
  },
  {
    args    => [ qq[a"b\nc] ],
    cmd     => undef,
    native  => qq["a\\"b\nc"],
    system  => 'native',
  },
  {
    args    => [ qq[a\fb] ],
    cmd     => qq[^"a\fb^"],
    native  => qq["a\fb"],
    system  => 'native',
  },
  {
    args    => [ qq[a\x0bb] ],
    cmd     => qq[^"a\x0bb^"],
    native  => qq["a\x0bb"],
    system  => 'native',
  },
  {
    args    => [ qq[a\x{85}b] ],
    cmd     => qq[^"a\x{85}b^"],
    native  => qq["a\x{85}b"],
    system  => 'native',
  }
) {
  my $name = dd($test->{args});
  my $native  = eval { quote_native(        @{ $test->{args} } ) };
  my $cmd     = eval { quote_cmd(           @{ $test->{args} } ) };
  my $system  = eval { quote_system_string( @{ $test->{args} } ) };

  is $native, $test->{native}, "$name as native";
  is $cmd,    $test->{cmd},    "$name as cmd";
  is $system, $test->{$test->{system}}, "$name as system -> $test->{system}";
  #TODO: AUTHOR_TESTING to verify valid data
}
done_testing;
