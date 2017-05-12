# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Workflow::Aline.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Workflow::Aline') };

use strict; use warnings;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

our $line;

my $factory = Workflow::Aline::ConveyorBelt::Factory->new( 
							   shall_create => 'Workflow::Aline::ConveyorBelt::Switch', 
							   
							   mixin_classes => [qw(Workflow::Aline::Pluggable::OneProximalOneDistal)], # isa

							   );
for ( 0..9 )
{    
    $line->{ $_ }  = $factory->create_new;

    warn sprintf "OBJECT %s address %s\n", ref( $line->{ $_ } ), $line->{ $_ }+0;
}

for ( 0..9 )
{    
    unless( $_ == 0 || $_ == 9 )
    {
	$line->{ $_ }->proximal( $line->{$_-1} );
	$line->{ $_ }->distal(   $line->{$_+1} );
	$line->{ $_ }->plug;
    }
}

use Data::Dumper;

print Dumper $line;

ok( $line );
