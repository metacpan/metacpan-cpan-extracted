#!/usr/bin/perl

# Testing the basic usage of asa.pm

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 18;

my $duck = Duck->new;
isa_ok( $duck, 'Duck' );
can_ok( $duck, 'quack' );
ok( ! $duck->{human}, 'Duck is not human' );
is( $duck->quack, 'Quack', 'A Duck quacks' );

my $wereduck = WereDuck->new;
isa_ok( $wereduck, 'WereDuck'    );
isa_ok( $wereduck, 'Lycanthrope' );
isa_ok( $wereduck, 'Duck'        );
isa_ok( $wereduck, 'Horror'      );
can_ok( $wereduck, 'morph' );
can_ok( $wereduck, 'quack' );
is( $wereduck->{human}, 1, 'A WereDuck is human' );
is( $wereduck->quack, 'Hi! I mean Quack!', 'A wereduck quacks' );

my $broken = BrokenDuck->new;
isa_ok( $broken, 'BrokenDuck'  );
isa_ok( $broken, 'Lycanthrope' );
isa_ok( $broken, 'Duck'        );
can_ok( $broken, 'morph' );
is( $broken->can('quack'), undef, "A BrokenDuck can't quack" );
eval "$broken->quack";
ok( $@, 'A BrokenDuck dies if it tries to quack' );

exit(0);


#####################################################################
# Packages used for testing

package Duck;

use strict;
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}

sub new { bless {}, $_[0] }

sub quack { 'Quack' }

1;

###################

package Lycanthrope;

use strict;
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}

sub new { bless { human => 1 }, $_[0] }

sub morph { 'HRALGLAHRLAHRAL' };

1;

###################

package WereDuck;

use strict;
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}

use base 'Lycanthrope';
use asa  'Duck', 'Horror';

sub quack { 'Hi! I mean Quack!' }

1;

####################

package BrokenDuck;

use strict;
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}

use base 'Lycanthrope';
use asa  'Duck';

1;
