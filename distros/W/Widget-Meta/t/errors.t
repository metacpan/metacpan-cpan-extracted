#!/usr/bin/perl -w

use strict;
use Test::More tests => 25;
use File::Spec;
my $metafn = File::Spec->catfile(qw(Widget Meta.pm));

BEGIN { use_ok('Widget::Meta') }

# Make sure we get an error with an odd number of parameters to new().
eval { Widget::Meta->new(1) };
chk('Widget::Meta->new odd parameters',
    qr/Odd number of parameters in call to new\(\) when named parameters were expected/);

# Make sure we get an error with a non-integer for each of the integer
# parameters.
for my $p (qw(rows cols length size)) {
    eval { Widget::Meta->new( $p => 'foo') };
    my $up = ucfirst $p;
    chk("$p must be an integer",
        qr/$up parameter must be an integer/);
}

# Make sure we get an error for a non-code-or-array reference for options.
eval { Widget::Meta->new(options => 'foo') };
chk( 'options must be code or array',
     qr/Options must be either an array of arrays or a code reference/);

##############################################################################
# This function handles all the tests.
##############################################################################
sub chk {
    my ($name, $qr) = @_;
    # Catch the exception.
    ok( my $err = $@, "Caught $name error" );
    # Check its message.
    like( $err, $qr, "Correct error" );
    # Make sure it refers to this file.
    like( $err, qr/(?:at\s+\Q$0\E|\Q$0\E\s+at)\s+line/, 'Correct context' );
    # Make sure it doesn't refer to Widget::Meta files.
    unlike( $err, qr|\Q$metafn\E|, 'Not incorrect context')
}
