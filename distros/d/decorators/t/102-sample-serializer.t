#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Data::Dumper;

BEGIN {
	# load from t/lib
	use_ok('Jaxsun::Trait::Provider');
	use_ok('Jaxsun::Trait::Handler');
}

=pod

This is an example of being able to
take no action and tag methods for
later use. In this case, we look
for the specific property and then
act upon it.

=cut

BEGIN {
	package Person;
	use strict;
	use warnings;

	use decorators 'Jaxsun::Trait::Provider';

	use parent 'UNIVERSAL::Object';
    our %HAS; BEGIN { %HAS = (
		first_name => sub { "" },
		last_name  => sub { "" },
	)};

	sub first_name : JSONProperty {
		my $self = shift;
		$self->{first_name} = shift if @_;
		$self->{first_name};
	}

	sub last_name : JSONProperty {
		my $self = shift;
		$self->{last_name} = shift if @_;
		$self->{last_name};
	}
}

my $JAX = Jaxsun::Trait::Handler->new( JSON::PP->new->canonical );

my $p = Person->new( first_name => 'Bob', last_name => 'Smith' );
isa_ok($p, 'Person');

is($p->first_name, 'Bob', '... got the expected first_name');
is($p->last_name, 'Smith', '... got the expected last_name');

my $json = $JAX->collapse( $p );
is($json, q[{"first_name":"Bob","last_name":"Smith"}], '... got the JSON we expected');

my $obj = $JAX->expand( Person => $json );
isa_ok($obj, 'Person');

is($obj->first_name, 'Bob', '... got the expected first_name');
is($obj->last_name, 'Smith', '... got the expected last_name');

done_testing;

