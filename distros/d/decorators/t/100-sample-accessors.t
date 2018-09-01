#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Data::Dumper;

=pod

This is an example of a simple provider
that will immediately build accessors
and overwrite the method.

=cut

BEGIN {
    package Person;

    use strict;
    use warnings;

    use decorators ':accessors';

    use parent 'UNIVERSAL::Object';
    our %HAS; BEGIN { %HAS = (
        fname => sub { "" },
        lname => sub { "" },
    )};

    sub first_name : ro(fname);
    sub last_name  : rw(lname);

    package Employee;

    use strict;
    use warnings;

    use decorators ':accessors';

    use parent -norequire => 'Person';
    our %HAS; BEGIN { %HAS = (
        %Person::HAS,
        title => sub { "" },
    )};

    sub title : ro;
}

my $p = Person->new( fname => 'Bob', lname => 'Smith' );
isa_ok($p, 'Person');

can_ok($p, 'first_name');
can_ok($p, 'last_name');

is($p->first_name, 'Bob', '... got the expected first_name');
is($p->last_name, 'Smith', '... got the expected last_name');

$p->last_name('Jones');

is($p->last_name, 'Jones', '... got the expected last_name');

my $e = Employee->new( fname => 'John', lname => 'Anderson', title => 'Programmer' );
isa_ok($e, 'Employee');
isa_ok($e, 'Person');

can_ok($e, 'first_name');
can_ok($e, 'last_name');
can_ok($e, 'title');

is($e->first_name, 'John', '... got the expected first_name');
is($e->last_name, 'Anderson', '... got the expected last_name');
is($e->title, 'Programmer', '... got the expected title');

done_testing;

