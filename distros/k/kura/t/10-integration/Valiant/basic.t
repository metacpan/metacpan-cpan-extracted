use Test2::V0;
use Test2::Require::Module 'Valiant', '0.002004';
use Test2::Require::Module 'Type::Tiny', '2.000000';

use FindBin qw($Bin);
use lib "$Bin";

use TestValiant qw(ValidLocalPerson);
use LocalPerson;

subtest 'Test `kura` with Valiant' => sub {
    isa_ok ValidLocalPerson, 'Type::Tiny';

    my $person1 = LocalPerson->new(name=>'foo');
    my $person2 = LocalPerson->new(name=>'too long naaaaaaame');

    ok ValidLocalPerson->check($person1);
    ok !ValidLocalPerson->check($person2);
};

done_testing;
