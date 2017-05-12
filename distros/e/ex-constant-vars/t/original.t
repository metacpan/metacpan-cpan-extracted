# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 20 };

use ex::constant::vars;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# it's man page ( perldoc Test ) for help writing this test script.

# Scalars

ok( tie my $s, 'ex::constant::vars', 100 );

ok( $s == 100 );

eval { $s++ };
ok( $@ );

eval { chop $s };
ok( $@ );

# Arrays

use ex::constant::vars 'const';
ok(1);

ok( const ARRAY my @a, qw( John Jane ) );

ok( $a[1] eq 'Jane' );

eval { unshift @a, 'Mother in Law' };
ok( $@ );

eval { push @a, 'Little Sally' };
ok( $@ );

eval { shift @a };
ok( $@ );

eval { $a[1] =~ tr/J/B/ };
ok( $@ );

ok( exists $a[1] );

# Hashes

use ex::constant::vars (
  '%h' => { John => 27, Jane => 'Back off!' },
);
ok(1);

ok( exists $h{Jane} );

ok( defined $h{$_} ) foreach keys %h;

eval { delete $h{John} };
ok( $@ );

eval { $h{'Little Sally'} = 0 };
ok( $@ );

eval { $h{Jane} = 26 };
ok( $@ );
