#!perl

use strict;
use warnings;

use Test::More qw[no_plan];

BEGIN {
    use_ok('UNIVERSAL::Object::Immutable');
}

{
    package Person;
    use strict;
    use warnings;

    our @ISA = ('UNIVERSAL::Object::Immutable');
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
        job_roles => sub { +[] },
        manager   => sub {},
    );

    sub job_title { $_[0]->{job_title} }
    sub job_roles { $_[0]->{job_roles} }
    sub manager   { $_[0]->{manager}   }
}

{

    my $p = Person->new(
        name   => 'stevan',
        age    => 43,
        gender => 'm',
    );
    isa_ok($p, 'Person');
    isa_ok($p, 'UNIVERSAL::Object::Immutable');
    isa_ok($p, 'UNIVERSAL::Object');

    is($p->name, 'stevan', '... got the value we expected');
    is($p->age, 43, '... got the value we expected');
    is($p->gender, 'm', '... got the value we expected');

    eval { $p->{name} = 'bob' };
    like($@, qr/^Modification of a read-only value attempted/, '... got the expected error');

    eval { $p->{nmae} = 'bob' };
    like($@, qr/^Attempt to access disallowed key \'nmae\' in a restricted hash/, '... got the expected error');

    eval { $p->{age}++ };
    like($@, qr/^Modification of a read-only value attempted/, '... got the expected error');

    is($p->name, 'stevan', '... got the value we expected');
    is($p->age, 43, '... got the value we expected');
    is($p->gender, 'm', '... got the value we expected');
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
        job_roles => ['program', 'compile'],
        manager   => $bob,
    );
    isa_ok($e, 'Employee');
    isa_ok($e, 'Person');
    isa_ok($e, 'UNIVERSAL::Object::Immutable');
    isa_ok($e, 'UNIVERSAL::Object');

    is($e->name, 'stevan', '... got the value we expected');
    is($e->age, 43, '... got the value we expected');
    is($e->gender, 'm', '... got the value we expected');
    is($e->job_title, 'developer', '... got the value we expected');
    is($e->manager, $bob, '... got the value we expected');
    is_deeply($e->job_roles, ['program', 'compile'], '... got the expected job roles');

    $@ = undef;
    eval { $e->{name} = 'bob' };
    like($@, qr/^Modification of a read-only value attempted/, '... got the expected error');

    $@ = undef;
    eval { $e->{nmae} = 'bob' };
    like($@, qr/^Attempt to access disallowed key \'nmae\' in a restricted hash/, '... got the expected error');

    $@ = undef;
    eval { $e->{age}++ };
    like($@, qr/^Modification of a read-only value attempted/, '... got the expected error');

    $@ = undef;
    eval { $e->{job_title} = 'boss' };
    like($@, qr/^Modification of a read-only value attempted/, '... got the expected error');

    $@ = undef;
    eval { $e->{manager} = $e };
    like($@, qr/^Modification of a read-only value attempted/, '... got the expected error');

    $@ = undef;
    eval { $e->{job_roles} = [] };
    like($@, qr/^Modification of a read-only value attempted/, '... got the expected error');

    $@ = undef;
    eval { push @{ $e->{job_roles} } => 'deploy' };
    ok(not($@), '... failed to get an error, as expected');

    is($e->name, 'stevan', '... got the value we expected');
    is($e->age, 43, '... got the value we expected');
    is($e->gender, 'm', '... got the value we expected');
    is($e->job_title, 'developer', '... got the value we expected');
    is($e->manager, $bob, '... got the value we expected');
    is_deeply($e->job_roles, ['program', 'compile', 'deploy'], '... got the expected job roles (along with our addition)');

}

