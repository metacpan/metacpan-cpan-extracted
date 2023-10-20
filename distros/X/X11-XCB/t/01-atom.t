#!perl
# vim:ts=4:sw=4:expandtab

use Test::More tests => 9;
use Test::Deep;
use Test::Exception;
use X11::XCB qw(:all);

BEGIN {
    use_ok('X11::XCB::Atom') or BAIL_OUT('Unable to load X11::XCB::Atom');
}

my $x;

# All atom tests need a working X connection, so we may need to skip them
SKIP: {
    eval { $x = X11::XCB::Connection->new; };

    skip "Could not setup X11 connection", 8 if $@ or $x->has_error();

    my $atom = $x->atom(name => 'PRIMARY');

    isa_ok($atom, 'X11::XCB::Atom');

    is(int($atom->id), $atom->id, 'reply is an integer');

    my $invalid = $x->atom(name => 'this_atom_does_not_exist');

    # We should be able to create the object
    isa_ok($invalid, 'X11::XCB::Atom');

    # This should crash
    throws_ok { $invalid->id } qr/No such atom/, 'Invalid atom die()d';

    ok(!$invalid->exists, 'Invalid atom does not exist');

    ok($atom->exists, 'Valid atom exists');

    my $other_invalid = $x->atom(name => 'this_atom_does_not_exist_too');

    # We should be able to create the object
    isa_ok($other_invalid, 'X11::XCB::Atom');

    ok(!$other_invalid->exists, 'Fresh invalid atom does not exist');
}

diag( "Testing X11::XCB, Perl $], $^X" );
