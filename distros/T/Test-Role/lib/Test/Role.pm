=head1 NAME

Test::Role - test that a class or object performs a role

=head1 SYNOPSIS

 use Test::Role;

 use Foo;
 does_ok(Foo, 'bar');

 my $foo = Foo->new;
 does_ok($foo, 'bar');

=head1 DESCRIPTION

Test::Role provides a test for classes and object that implement roles
using the Class::Roles module.

Test::Role exports a single function B<does_ok>. B<does_ok> takes two
required arguments: a class or object and a role which that class or object
must perform. A third optional argument may be used to provide a more
specific name of what is being testing (for example 'Test customer'). in the
absence of this argument, 'the object' will be used instead.

Test::Role is implemented using Test::Builder, so it's tests integrate
seamlessly with other test modules such as Test::More and Test::Exception.

=begin testing

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

=end testing

=cut

package Test::Role;

use strict;

use Test::Builder;
use Class::Roles;

require Exporter;
use vars qw($VERSION @ISA @EXPORT %EXPORT_TAGS);

$VERSION = 0.012_000;
@ISA     = 'Exporter';
@EXPORT  = qw|does_ok|;

my $Test = Test::Builder->new;

sub does_ok($$;$)
{
    
    my($object, $role, $obj_name) = @_;
    $obj_name = 'the object' unless defined $obj_name;
    my $name = "$obj_name performs the $role role";
    my $diag;
    if( !defined $object ) {
        $diag = "$obj_name isn't defined";
    }
    else {
        local($@, $!);  # eval sometimes resets $!
        my $rslt = eval { UNIVERSAL::does($object, $role) };
        if( $@ ) {
            die <<WHOA;
WHOA! I tried to call UNIVERSAL::does on your object and got some weird
error. This should never happen.  Please contact the author immediately.
Here's the error.
$@
WHOA
        }
        elsif( !$rslt ) {
            $diag = "$obj_name doesn't perform the $role role";
        }
    }

    my $ok;
    if( $diag ) {
        $ok = $Test->ok(0, $name);
        $Test->diag("    $diag\n");
    }
    else {
        $ok = $Test->ok(1, $name);
    }
    
    return $ok;
    
}

# keep require happy
1;


__END__

=head1 TODO

Update once Class::Roles (by chromatic) and Class::Role (another 'trait'
implementation by Luke Palmer) are merged in the near future.

=head1 ACKNOWLEDGEMENTS

Michael Schwern for Test::Builder::isa_ok on which this is based.

chromatic for Class::Roles, this module's raison d'etre.

=head1 SEE ALSO

L<Test::Builder>

L<Class::Roles>

=head1 AUTHOR

James FitzGibbon E<lt>jfitz@CPAN.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2003, James FitzGibbon.  All Rights Reserved.

This module is free software. You may use it under the same terms as perl
itself.

=cut

#
# EOF

