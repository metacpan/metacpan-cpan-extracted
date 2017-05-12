#!/usr/local/bin/perl -w

use Test::More tests => 14;

package Catch;

sub TIEHANDLE {
    my($class, $var) = @_;
    return bless { var => $var }, $class;
}

sub PRINT  {
    my($self) = shift;
    ${'main::'.$self->{var}} .= join '', @_;
}

sub OPEN  {}    # XXX Hackery in case the user redirects
sub CLOSE {}    # XXX STDERR/STDOUT.  This is not the behavior we want.

sub READ {}
sub READLINE {}
sub GETC {}

my $Original_File = 'lib/Test/Role.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;

package Bar;

use Class::Roles role => 'bar';

sub bar { 'bar' }

package Foo;

use Class::Roles does => 'bar';

sub new { return bless {}, $_[0] }

package main;

BEGIN {
    use_ok('Test::Role');
    use_ok('Test::Builder::Tester');
};
ok( defined(&does_ok), "function 'does_ok' is exported");

does_ok('Foo', 'bar');
does_ok('Foo', 'bar', 'the Foo class');

my $foo = Foo->new;
does_ok($foo, 'bar');
does_ok($foo, 'bar', 'the $foo object');

test_out("ok 1 - the object performs the bar role");
does_ok('Foo', 'bar');
test_test("does_ok works with default name");

test_out("ok 1 - the Foo class performs the bar role");
does_ok('Foo', 'bar', 'the Foo class');
test_test("does_ok works with explicit name");

test_out("not ok 1 - an undefined object performs the foo role");
test_fail(+2);
test_diag("    an undefined object isn't defined");
does_ok(undef, 'foo', 'an undefined object');
test_test("does_ok fails with undefined invocant");

test_out("not ok 1 - the object performs the foo role");
test_fail(+2);
test_diag("    the object doesn't perform the foo role");
does_ok('Foo', 'foo');
test_test("does_ok fails for a class without a name");

test_out("not ok 1 - the Foo class performs the foo role");
test_fail(+2);
test_diag("    the Foo class doesn't perform the foo role");
does_ok('Foo', 'foo', 'the Foo class');
test_test("does_ok fails for a class with a name");

test_out("not ok 1 - the object performs the foo role");
test_fail(+2);
test_diag("    the object doesn't perform the foo role");
does_ok($foo, 'foo');
test_test("does_ok fails for an object without a name");

test_out('not ok 1 - the $foo object performs the foo role');
test_fail(+2);
test_diag("    the \$foo object doesn't perform the foo role");
does_ok($foo, 'foo', 'the $foo object');
test_test("does_ok fails for an object with a name");


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

