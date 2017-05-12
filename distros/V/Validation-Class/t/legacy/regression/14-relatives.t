use Test::More tests => 11;

BEGIN {
    use FindBin;
    use lib $FindBin::Bin . "/modules";
}

use_ok 'MyVal';

my $rules = MyVal->new(params => {flag => 1});

my $chk_person = $rules->class('person');
my $chk_ticket = $rules->class('ticket');

ok "MyVal::Person" eq ref($chk_person), 'person class loaded successfully';
ok "MyVal::Ticket" eq ref($chk_ticket), 'ticket class loaded successfully';

ok $chk_person->fields->{name},  'person class has name';
ok $chk_person->fields->{email}, 'person class has email';
ok !$chk_person->fields->{description}, 'person class doesnt have description';
ok !$chk_person->fields->{priority},    'person class doesnt have priority';

ok !$chk_ticket->fields->{name},  'ticket class doesnt have name';
ok !$chk_ticket->fields->{email}, 'ticket class doesnt have email';
ok $chk_ticket->fields->{description}, 'ticket class has description';
ok $chk_ticket->fields->{priority},    'ticket class has priority';
