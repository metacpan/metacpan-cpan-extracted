#!perl

use strict;
use warnings;

use Test::More qw[no_plan];

BEGIN {
	use_ok('UNIVERSAL::Object');
}

{
    package Person;
    use strict;
    use warnings;

    our @ISA = ('UNIVERSAL::Object');
    our %HAS = (
        name   => sub { die 'name is required' },
        age    => sub { 0 },
        gender => sub {},
    );

    sub name   { $_[0]->{name}   }
    sub age    { $_[0]->{age}    }
    sub gender { $_[0]->{gender} }

    package Employee;
    use strict;
    use warnings;

    our @ISA = ('Person');
    our %HAS = (
        %Person::HAS,
        job_title => sub { die 'job_title is required' },
        manager   => sub {},
    );

    sub job_title { $_[0]->{job_title} }
    sub manager   { $_[0]->{manager}   }
}

{

	my $p = Person->new(
		name   => 'stevan',
		age    => 43,
		gender => 'm',
	);
	isa_ok($p, 'Person');
	isa_ok($p, 'UNIVERSAL::Object');

	is($p->name, 'stevan', '... got the value we expected');
	is($p->age, 43, '... got the value we expected');
	is($p->gender, 'm', '... got the value we expected');
}

{

	my $p = Person->new(
		name   => 'stevan',
	);
	isa_ok($p, 'Person');
	isa_ok($p, 'UNIVERSAL::Object');

	is($p->name, 'stevan', '... got the value we expected');
	is($p->age, 0, '... got the value we expected');
	is($p->gender, undef, '... got the value we expected');
}

{
	eval { Person->new };
	like($@, qr/^name is required/, '... got the expected error');
}

{

	my $bob = Employee->new(
		name      => 'bob',
		job_title => 'people-manager'
	);

	my $e = Employee->new(
		name      => 'stevan',
		age       => 43,
		gender    => 'm',
		job_title => 'developer',
		manager   => $bob,
	);
	isa_ok($e, 'Employee');
	isa_ok($e, 'Person');
	isa_ok($e, 'UNIVERSAL::Object');

	is($e->name, 'stevan', '... got the value we expected');
	is($e->age, 43, '... got the value we expected');
	is($e->gender, 'm', '... got the value we expected');
	is($e->job_title, 'developer', '... got the value we expected');
	is($e->manager, $bob, '... got the value we expected');
}

{

	my $e = Employee->new(
		name      => 'stevan',
		job_title => 'developer'
	);
	isa_ok($e, 'Employee');
	isa_ok($e, 'Person');
	isa_ok($e, 'UNIVERSAL::Object');

	is($e->name, 'stevan', '... got the value we expected');
	is($e->age, 0, '... got the value we expected');
	is($e->gender, undef, '... got the value we expected');
	is($e->job_title, 'developer', '... got the value we expected');
	is($e->manager, undef, '... got the value we expected');
}

{
	eval { Employee->new( job_title => 'developer' ) };
	like($@, qr/^name is required/, '... got the expected error');

	eval { Employee->new( name => 'stevan' ) };
	like($@, qr/^job_title is required/, '... got the expected error');
}


