use Test::More tests => 18;

BEGIN {
    use FindBin;
    use lib $FindBin::Bin . "/modules";
}

use_ok 'MyVal::Person';
use_ok 'MyVal::Ticket';

package val::a;

use Validation::Class;

mixin TMP => {
    required => 1,
    between  => '1-255'
};

field name => {
    mixin => 'TMP',
    label => 'Person\'s name'
};

field email => {
    mixin => 'TMP',
    label => 'Person\'s email'
};

package val::b;

use Validation::Class;

field description => {
    mixin => 'TMP',
    label => 'Ticket description'
};

field priority => {
    mixin   => 'TMP',
    label   => 'Ticket priority',
    options => [qw/Low Normal High Other/]
};

{

    package val::test1;

    use Test::More;

    my $foo = val::a->new(params => {flag => 0});
    my $bar = val::b->new(params => {flag => 0});

    ok $foo->fields->{name},  'foo has name';
    ok $foo->fields->{email}, 'foo has email';
    ok !$foo->fields->{description}, 'foo doesnt have description';
    ok !$foo->fields->{priority},    'foo doesnt have priority';

    ok !$bar->fields->{name},  'bar doesnt have name';
    ok !$bar->fields->{email}, 'bar doesnt have email';
    ok $bar->fields->{description}, 'bar has description';
    ok $bar->fields->{priority},    'bar has priority';
}

{

    package val::test2;

    use Test::More;

    my $foo = MyVal::Person->new(params => {flag => 1});
    my $bar = MyVal::Ticket->new(params => {flag => 1});

    ok $foo->fields->{name},  'foo has name';
    ok $foo->fields->{email}, 'foo has email';
    ok !$foo->fields->{description}, 'foo doesnt have description';
    ok !$foo->fields->{priority},    'foo doesnt have priority';

    ok !$bar->fields->{name},  'bar doesnt have name';
    ok !$bar->fields->{email}, 'bar doesnt have email';
    ok $bar->fields->{description}, 'bar has description';
    ok $bar->fields->{priority},    'bar has priority';
}
